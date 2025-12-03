+++
title = "Various types of latencies in a Python WSGI stack fronted with ALBs"
tags = ["python", "aws", "uwsgi", "nginx", "kubernetes"]
description = "Clarifying some misconceptions around scaling strategies, latencies and how they play together"
date = "2025-12-02T22:19:15Z"
+++

At work we use Django/UWSGI/Nginx/AWS ALB across a lot of our services. We have many partners connecting to our API servers with all sorts of automation. A lot of these partners don't have mechanisms to rate limit their outbound requests, so we need to either maintain enough capacity (by tweaking number of pods) or make sure we can scale rapidly when load hits. Not all our systems have the same scaling setup - some are better configured than others.

For one particular system, clients were reporting 10+ second response times, but our application logs showed requests completing in under 3 seconds. Where was the time going?

At peak time, the service was getting hit with a lot of concurrent requests - way more than could be serviced simultaneously. The autoscaler was set up to trigger on CPU usage, but it wasn't scaling nearly enough replicas to handle the load. Meanwhile, clients were timing out left and right.

The confusing bit: application logs showed reasonable response times, but clients were seeing something completely different.

## The ALB Doesn't Queue (Not Really)

First thing to clear up: **ALBs don't maintain a queue of pending requests**. The ALB operates by maintaining two separate connections - one front-end connection with the client and one back-end connection with your target. It does terminate the TCP connection from the client (so it reads headers and ACKs data to make routing decisions), but crucially, it doesn't buffer up a bunch of requests in memory waiting for slow backends.

From AWS docs, when the ALB receives a request it will:
- Try to establish a connection with your target within 10 seconds
- Return a 504 if it can't
- Track failures through `TargetConnectionErrorCount`
- Reject connections when it hits its own limits (tracked via `RejectedConnectionCount`)

The ALB reads HTTP headers to figure out where to route the request, then forwards it to the appropriate target. But it's not sitting there with a work queue. If the backend is slow to accept connections, the client connection just waits (up to timeout).

The ALB handles connections asynchronously, so one slow connection doesn't block others - each connection is independent. There's no intermediate queue where requests pile up waiting their turn.

So when you see requests queueing, it's happening lower in the stack:
- Linux networking layer (socket backlog)
- Nginx connection handling
- UWSGI listen queue

## Understanding Backpressure Management

Here's where I have seen lots of people getting confused. The queueing behavior isn't a bug - it's **backpressure management**, and every system needs it.

Think about what happens without backpressure:
1. Service receives 10,000 requests per second
2. All 10,000 get immediately accepted
3. Service tries to process all 10,000 simultaneously
4. Runs out of memory/connections/file descriptors
5. Crashes

With backpressure, the system can say "hold on, I'm busy" and make requests wait in a queue rather than accepting unbounded load. The queue has a finite size, and once it fills up, new connections get rejected with an error. This is much better than crashing.

## Where Requests Actually Queue

Let's visualize the full request path:

```
Client Request
    ↓
┌─────────────────────────┐
│   AWS Load Balancer     │  No queueing here
│   (ALB)                 │  Pass-through proxy
└─────────────────────────┘
    ↓
┌─────────────────────────┐
│   Nginx Listen Queue    │  First potential queue
│   (backlog=4096)        │  Linux socket backlog
└─────────────────────────┘
    ↓
┌─────────────────────────┐
│   Nginx Worker          │  Accepts and forwards
│   (max_conns limit)     │  Connection limiting
└─────────────────────────┘
    ↓
┌─────────────────────────┐
│   UWSGI Socket Queue    │  Second major queue
│   (listen=2048)         │  Where most queueing happens
└─────────────────────────┘
    ↓
┌─────────────────────────┐
│   UWSGI Worker          │  ← Timing starts HERE
│   (4 processes)         │  Application finally sees request
└─────────────────────────┘
    ↓
┌─────────────────────────┐
│   Django Application    │  Your code runs
└─────────────────────────┘
```

**The key insight**: UWSGI only starts timing the request once a worker accepts the connection from the socket backlog. Everything before that is invisible to your application logs.

## How Socket Backlog works

When you configure UWSGI with `listen = 2048`, you're not setting some UWSGI-specific queue. You're configuring the **Linux socket backlog** - a standard Unix feature.

From the Linux `listen()` manual:
> "The backlog parameter defines the maximum length to which the queue of pending connections for the socket may grow."

When this backlog fills up:
- New connections receive `ECONNREFUSED` errors
- Or the protocol might ignore them for later retry
- The max value is capped by the host's `net.core.somaxconn`

In containerized environments, there's an extra thing to remember. You might configure UWSGI with `listen=2048` or Nginx with `backlog=4096`, but if your container doesn't have the right security context, the syscall to actually set that value will fail or be silently capped. We had to add specific securityContext settings to our pod specs to allow these syscalls. Without those permissions, you're stuck with whatever lower default the container runtime enforces.

The UWSGI docs confirm the default is around 100 slots, but you can push it higher. Similarly, Nginx has its own listen backlog that you can configure.

Here's what actually happens during peak load:

```
Time from client perspective:
┌──────────────────────────────────────────────────┐
│ Total time: ~10 seconds                          │
│                                                  │
│  ALB routing: 10ms                               │
│  Nginx backlog wait: 50ms                        │
│  UWSGI socket backlog: 7500ms ← HERE!            │
│  Django processing: 2000ms                       │
│  Response: 50ms                                  │
└──────────────────────────────────────────────────┘

Time in application logs:
┌──────────────────────────────────────────────────┐
│ Logged time: ~2 seconds                          │
│                                                  │
│  Django processing: 2000ms                       │
└──────────────────────────────────────────────────┘
```

The disconnect between these two views is your socket backlog queueing time.

## Why Backpressure Management Matters

The socket backlog is doing exactly what it's designed to do: providing a buffer for temporary load spikes. The problem is when "temporary" becomes "sustained."

With the actual configuration in our case:
- A few worker processes per pod (single digits)
- Generous socket backlog (thousands of slots)
- Not enough pods to handle peak load

The math doesn't work out. You can only actively process as many requests as you have workers. Everything else queues. If you have hundreds of requests queuing up, and each request takes a couple seconds to process, you're looking at serious latency even though your application "feels" fast from its own perspective.

This is backpressure working as intended - preventing crashes - but indicating you need more capacity.

## CPU-Based Autoscaling Falls Apart

Here's the problem with CPU-based autoscaling for synchronous Django apps: if your workers spend most of their time waiting on database queries or external APIs, CPU utilization doesn't tell you much.

The scenario we hit:
- Workers blocked on database queries (I/O wait)
- CPU shows 50% utilization
- Autoscaler: "looks fine!"
- Socket backlogs: completely full
- Clients: timing out

CPU measures compute activity, but the bottleneck is I/O capacity. Different resources entirely.

If all the UWSGI workers are blocked waiting for the database or external APIs to return, your system has zero workers available to accept new connections. The socket backlogs fill up, and eventually the ALB can't establish new connections to your targets. At that point, the ALB starts returning errors to clients - your capacity is effectively zero even though you have pods running.

## Finding the Missing Time

The CloudWatch metric that reveals everything is **TargetResponseTime**:
> "The time elapsed, in seconds, after the request leaves the load balancer until the target starts to send the response headers"

This captures:
- Connection establishment from ALB to target
- Time in Nginx queues
- **Time in UWSGI socket backlog** ← Usually the smoking gun
- Worker processing time
- Django execution time

In our setup, Nginx is typically pretty fast at accepting connections and forwarding them to UWSGI. The UWSGI socket backlog is where requests really pile up because that's where they're waiting for an actual worker process to become available. Nginx can accept and forward quickly, but if all UWSGI workers are busy, connections sit in that UWSGI socket backlog.

Compare this with your application logs. The gap is time spent queueing.

Other useful metrics:
- **TargetConnectionErrorCount**: Backends refusing connections (socket backlog full)
- **RejectedConnectionCount**: ALB hitting its own limits
- **RequestCountPerTarget**: Load distribution across targets

In the debugging session, CloudWatch showed requests plateauing at 10 seconds (client timeout) while UWSGI logs showed nothing over 2-3 seconds. That's an 7-8 second gap sitting in socket backlogs.

## Better Approaches

### 1. Scale on Request Count, Not CPU

Some of our services are moving toward KEDA with HTTP add-on (Kedify) to scale based on actual incoming load. Here's how a typical configuration look like:

```yaml
httpScaler:
  enabled: true
  targetValue: 100  # concurrent requests per replica
  minReplicas: 2
  maxReplicas: 45
```

The `targetValue` should roughly match your UWSGI concurrency - that is, the number of workers (processes) times threads if you're using them. If you have 4 processes and no threading, your actual concurrency is 4, so a targetValue of 100 would be way too high. You'd want something closer to your actual worker count.

This responds directly to the actual problem - too many requests, not enough workers - instead of waiting for CPU to maybe reflect it.

### 2. Scale on Response Time (With Caveats)

Monitoring ALB `TargetResponseTime` and scaling when it crosses a threshold sounds appealing, but it's tricky. That metric includes everything: socket backlog queueing, worker processing time, and database query time.

If your backends are hitting heavily used databases, high `TargetResponseTime` might mean your database is slow, not that you need more pods. Scaling up would just give you more workers all waiting on the same slow database. You need to correlate it with other signals to know if it's actually a capacity problem.

### 3. Increase Worker Count Per Pod

If you're running just a handful of workers per pod, you might be underutilizing your hardware. Modern pods can often handle 8-16 workers comfortably, depending on memory allocation, database connection pool size, and whether your Django code is actually thread-safe (if you're using threads).

### 4. Socket Backlogs Are a Buffer, Not a Fix

A large socket backlog (2048+) gives you buffer for temporary spikes. But it's not solving the underlying problem. If your backlogs are consistently full, you need more workers or better scaling, not bigger queues.

## Wrapping Up

When clients report higher latency than your logs show, the missing time is almost always in socket backlogs. Your application never sees this because timing only starts after a worker accepts the connection.

We use Datadog APM to instrument our Python stack, which is great for understanding what's happening inside the application. But it doesn't show you socket backlog queueing time. For that, you need to look at ALB CloudWatch metrics like `TargetResponseTime`. That metric captures the full journey from when the request leaves the load balancer to when the response starts coming back - including all the queueing.

The fix isn't necessarily "throw more pods at it." It's more about scaling on the right metrics (request count works better than CPU for I/O-bound apps), tuning worker counts to match your hardware, and monitoring metrics at each stage - ALB, Nginx, UWSGI - not just what your APM tooling shows you.

The gap between what CloudWatch shows and what your application instrumentation shows is where requests sit waiting in queues.

## References

- [AWS ALB CloudWatch Metrics](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-cloudwatch-metrics.html)
- [AWS ALB Troubleshooting](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-troubleshooting.html)
- [UWSGI Listen Queue](https://uwsgi-docs.readthedocs.io/en/latest/articles/TheArtOfGracefulReloading.html)
- [Linux Socket Backlog](https://man7.org/linux/man-pages/man2/listen.2.html)
