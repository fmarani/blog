+++
title = "Kubernetes QoS and Priority: Protecting Your Critical Workloads"
tags = ["kubernetes", "eks", "karpenter"]
description = "How QoS classes and Priority classes work together to determine what happens under node pressure"
date = "2026-01-08T20:00:00Z"
+++

When a Kubernetes node runs out of memory, the kernel's OOM killer will terminate processes and the kubelet will start evicting pods. But which pods get killed first? The answer depends on two systems working together: QoS classes and Priority classes.

## QoS Classes: Automatic Classification

Kubernetes assigns a QoS (Quality of Service) class to every pod based entirely on how you configure resource requests and limits. You don't set it directly - Kubernetes infers it from your pod spec.

**Guaranteed**: Every container in the pod has CPU and memory requests equal to their limits. This is the highest protection class.

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "500m"
  limits:
    memory: "256Mi"
    cpu: "500m"
```

**Burstable**: At least one container has requests or limits set, but they're not equal. The pod can burst above its requests up to its limits (or node capacity if no limit is set).

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "1000m"
```

**BestEffort**: No requests or limits set on any container. These pods get whatever resources are available and are first in line for eviction.

You can check a pod's QoS class with:

```
kubectl get pod <name> -o jsonpath='{.status.qosClass}'
```

For the full rules on how Kubernetes determines QoS class, see the [official documentation](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/).

## Why Guaranteed Gets Special Treatment

When you set requests equal to limits, Kubernetes treats those resources as fully reserved. Even if your Guaranteed pod is idle, other pods cannot use those resources. This is less efficient from a cluster utilization perspective, but it gives you predictable performance.

The bigger benefit for the type of workloads we run comes under memory pressure. The Linux kernel assigns each process an `oom_score_adj` value that influences which processes the OOM killer targets first. Kubernetes sets this value based on QoS class - Guaranteed pods get a very low score, making them unlikely to be killed. BestEffort pods get the maximum score, making them first targets.

The exact values and calculation are documented in the [node out-of-memory behavior](https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction/#node-out-of-memory-behavior) section of the Kubernetes docs.

## Priority Classes: Explicit Importance

While QoS is automatic, Priority classes are something you explicitly assign. You create a PriorityClass resource and reference it in your pod spec:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000
globalDefault: false
description: "For user-facing HTTP services"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 100000
globalDefault: false
description: "For background processing"
```

Then in your deployment:

```yaml
spec:
  template:
    spec:
      priorityClassName: high-priority
```

Priority affects two things: scheduling order (higher priority pods get scheduled first) and preemption (higher priority pods can kick out lower priority pods to make room).

At work we use this to differentiate between deployments that serve HTTP traffic versus deployments that handle background processing like RabbitMQ consumers. The HTTP-serving deployments get a higher priority class. When the cluster is resource-constrained, the scheduler will preempt background workers to make room for API pods. Users notice when the API is slow; they don't notice if a background job takes an extra minute.

## How They Work Together

The rule of thumb:

- **Priority** decides who gets a seat on the bus (scheduling) and who gets kicked off if someone more important shows up (preemption).
- **QoS** decides who gets thrown off the bus if the engine starts smoking (resource pressure eviction).

While the kubelet considers Priority as a tiebreaker during its eviction process, the Linux kernel OOM killer does not. If the node hits a hard memory wall, the kernel will kill a high-priority BestEffort pod before a low-priority Guaranteed pod every time.

The exception is pods with `system-node-critical` or `system-cluster-critical` priority classes - these are never evicted by the kubelet regardless of QoS class.

In practice, preemption rarely happens in our clusters. Karpenter provisions new nodes as needed without hard upper limits, and our ResourceQuotas are generous enough that we don't hit namespace-level constraints. Preemption mostly matters when capacity is genuinely scarce - during cloud provider outages or if you've capped your node count for cost control.

## Practical Guidelines

For our HTTP-serving deployments, we use:
- Guaranteed QoS (requests = limits)
- High priority class
- This ensures they get scheduled first, survive preemption, and are last to be killed under memory pressure

For background workers (RabbitMQ consumers, batch jobs):
- Burstable QoS (lower requests, higher limits to allow bursting)
- Lower priority class
- These can be preempted if needed, and will be evicted before the HTTP services

We avoid BestEffort in production entirely. It's fine for development clusters or throwaway debugging pods, but any workload you care about should have at least requests defined. You can enforce this with a ResourceQuota that specifies compute resources - pods without requests/limits will be rejected.

## Spot Instances and Node Recycling

If you're running Karpenter with spot instances or node TTL expiration, there's another dimension to consider. Spot interruptions and node recycling are **voluntary disruptions** - they're not triggered by resource pressure, so the QoS-based eviction order doesn't apply.

When AWS reclaims a spot instance, Karpenter gets a 2-minute warning. It cordons the node and drains pods using the Kubernetes eviction API. The same happens when a node hits its TTL expiry. In both cases, what protects your pods is **PodDisruptionBudgets**, not QoS class. Priority still matters, but mainly for rescheduling order - higher priority pods get placed on new nodes first.

| Scenario | What matters |
|----------|--------------|
| Memory pressure (OOM) | QoS class first, then Priority |
| Spot interruption | PDBs, then Priority for rescheduling |
| Node TTL expiry | PDBs, then Priority for rescheduling |
| Scheduler preemption | Priority only |

So for spot/TTL scenarios, your defenses are PodDisruptionBudgets to ensure minimum availability during drains, and high priority so your pods get rescheduled quickly onto new capacity. QoS class won't help you when Karpenter is intentionally draining a node - that's planned disruption, not resource pressure.

## The Trade-off

Guaranteed QoS means reserving resources that might sit unused. If your pod requests 2GB of memory but typically uses 500MB, that 1.5GB is unavailable to other pods even when idle. This is the cost of predictability.

Burstable lets you pack more workloads onto a cluster by overcommitting resources. It works well when not all pods peak at the same time. But when they do, something has to give - and the eviction order determines what.

Understanding these two systems helps you make informed decisions about how to configure your workloads. QoS and Priority are complementary: one handles runtime resource pressure, the other handles scheduling contention.

## References

- [Configure Quality of Service for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/)
- [Node Out-of-Memory Behavior](https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction/#node-out-of-memory-behavior)
- [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)
