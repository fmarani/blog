+++
title = "Three Years to Build Something Nobody Noticed"
tags = ["kubernetes", "retrospective"]
description = "A retrospective on three years migrating a Django platform to Kubernetes"
date = "2026-06-03T09:00:00Z"
+++

A couple of years ago we finished migrating our Django platform to Kubernetes. It took three years. It is now the infrastructure that runs our product for dozens of clients, handles their deployments, scales their workers, and manages their configuration. Most of the people using it every day have no idea how it works, or that there was anything before it. That is probably the right outcome for infrastructure. It is also a strange thing to sit with.

This is not a technical post — we published one of those [here](https://engineering.kraken.tech/news/2026/02/11/django-kubernetes-health-checks-continuous-delivery.html). Think of it as a retrospective on what three years of that kind of work actually feels like, for the benefit of anyone in the middle of something similar.

---

## What we inherited

The previous system worked, for the number of clients we had at the time. The problem was that it was not going to scale much beyond that. The management team already knew it had to be done — that part was not a hard sell. What was harder was the actual doing of it.

There was also the matter of understanding what we had. A lot of the infrastructure had been built over years with no real effort to document who knew what. People had left, yes, but that was not the main problem. The main problem was that we had never kept track of where the knowledge lived while they were still there. There were Consul keys nobody could explain. There were configuration decisions baked into Terraform modules with no comments and no git history that helped. Some things simply assumed we were running on VMs — that level of assumption was baked in deep. Before we could change anything, we had to understand it — and that understanding often took weeks, for things that should have taken days.

The Helm setup was a challenge of its own. The original author knew Helm well, which meant they had used a lot of its advanced features: complex templating, layered overrides, abstractions on top of abstractions. My instinct was that it was over-engineered, but I did not have enough experience at the time to be sure. I set it aside — we could always refactor it later, and it was not the blocker. Turns out my instinct was right, and what we are running today has little of what was originally there.

---

## Learning under fire

There is a kind of learning that happens when you have no alternative. You are responsible for the outcome, the deadline is implied if not explicit, and there is no documentation to speak of — just live systems to inspect. In my case, half of that time was spent trying to understand what we already had, and the other half learning Kubernetes and Helm from scratch, having never worked with either before.

At some point the person who had written the original Helm setup left the company. I became the person people came to with Kubernetes questions. I knew I still had a lot to learn, but I also knew I was the best placed person to answer them at that point. What made it harder was that I could see people doing things that were simply inappropriate for Kubernetes — patterns that would cause problems later — and felt the pressure to find and correct those things quietly before they got out of hand, without making it a confrontation. That is a tiring way to work.

---

## The migrations

I never asked for a downtime window. The honest reason is that I could not quantify the risk well enough to ask confidently, and I did not want to commit to a window and then discover mid-migration that something was wrong. Instead we spent months building bridging infrastructure: components that allowed both systems to run in parallel, routing traffic gradually, until we were confident enough to cut over. That work is invisible in the final system but it was a significant part of the project.

One of the trickier parts of running both systems in parallel was managing the traffic split. The solution we came up with was weighted DNS records in front of all load balancers, which allowed us to shift traffic gradually between old and new. The problem was making sure those records were not accidentally recreated by Terraform during the process. We were on Terraform 0.13 at the time, which did not support moving resources between states, so keeping everything consistent required a lot of manual state changes. Getting it wrong would have meant losing DNS records entirely, and with them, downtime.

The DNS weights gave us the ability to pull back quickly if something went wrong with HTTP traffic. Cronjobs were a different story. We run a lot of scheduled processing — billing, industry data reconciliation, things that touch financial records. Idempotence is a property we recommend, but in practice it is very hard to guarantee across complex, domain-specific flows. Running the same job twice in our industry means the risk of double-executing a transaction against an energy network. We had no emergency system for that. We just had to be careful, plan the cutover timing well, and accept that some risk was not fully eliminable. As far as I know, it never went wrong. I am not entirely sure how much of that was good engineering and how much was luck.

Each migration followed the same pattern: plan carefully, expect something to go wrong anyway, stay calm when it does. Most colleagues were not involved in the migrations directly. The business did not set deadlines, but I felt the weight of them regardless. At the time I found it isolating. Looking back, I think the isolation was just the nature of the work: the kind of thing where the responsibility concentrates regardless of what the org chart says.

---

## The rabbit holes

Some of the worst weeks of the project were not migrations — they were rabbit holes.

The worst was a network issue in one of our oldest environments. That environment had accumulated a large number of VPN connections to industry networks over the years, and several of them had serious IP allocation problems that had never been resolved because the old system had worked around them. The root of it was that the existing subnets were sized for VMs. Kubernetes assigns an IP per pod, and pods are a much finer-grained unit than VMs — it is roughly equivalent to every process inside a VM suddenly needing its own IP address. The subnets were nowhere near large enough for that, and the IP ranges were tightly coupled with what the industry partners had allowed on their end. We spent months in conversations with those partners, navigating their internal bureaucracies, trying to get the ranges corrected. The fix was technically straightforward. Getting permission to make it was not. We eventually got there, but it was months I would rather have spent elsewhere.

The KEDA pivot was harder to stomach, because it came mid-project. We had migrated most of our smaller clients and all of our test environments using HPA with CPU and memory metrics. It worked well enough at small scale. When we started migrating our largest clients, we saw clearly that it did not work at scale — our workloads are I/O-bound, not CPU-bound, and CPU utilisation is a poor proxy for queue pressure. We had to go back and rethink the autoscaling approach entirely. KEDA, scaling on application metrics like queue depth and worker occupancy, was the right answer. But arriving at it after most of the work was done was a blow.

The pattern in both cases was the same: you start down a path that seems reasonable, you invest weeks or months, and then you discover either that the path is wrong or that something outside your control is blocking it. In both cases there was no way to push through — we had to backtrack and start again. That is not a pleasant feeling, but it is sometimes the only option.

---

## The team dynamic

The pressure I felt throughout the project was self-imposed. I knew the old deployment pipeline was slow, suboptimal, and would not scale, and I felt that urgency in a way that was not evenly distributed across the team.

There were periods where colleagues were deep in technical explorations — networking configurations, tooling choices — some of which made it into the final system, some of which did not. I understood why it happened. The technical problems are genuinely interesting, and without a forcing function it is easy to spend time on things that feel productive but are not on the critical path. What I found harder to manage was my own frustration with it. The technical bits are safe ground — you can explore, backtrack, try again. Migrations are not. Nobody was assigned to do them. I did them anyway, because somebody had to.

I do not think there was a villain in this, and I was not always right either. Some of the rabbit holes were my own choices. The over-engineering in the early Helm work was partly inherited, but I also made decisions under uncertainty that I would make differently now. A lot of what felt like the project being hard was just me not having done this before. That is not a criticism — you cannot have done something before the first time you do it — but it is worth being honest about. The shape of the work concentrates responsibility in the person who feels the urgency most, and that person is not always the most experienced one.

---

## The silence after

After all migrations were done, there was little public acknowledgement of it.

A lot of new engineers have joined the company since then. They have never seen the previous system. To them, Kubernetes and GitOps deployments are just how things work here. That is fine — it is actually the right outcome. Infrastructure that draws attention to itself is usually infrastructure that is failing.

But there is a cost to an organisation that cannot name what was hard. It means you cannot plan well for the next hard thing. You cannot calibrate what resourcing those projects actually require. You cannot have an honest conversation about why they take as long as they do. The work becomes invisible in the same moment that it succeeds, and without deliberate effort to record it, the knowledge of what it cost disappears too.

---

## A few things I would tell someone mid-migration

The loneliness is real. It does not mean you are doing it wrong.

Rabbit holes are part of large infrastructure projects. You will not avoid them all. The best you can do is notice when you are in one, and be honest with yourself about whether you are still making progress or just unwilling to write off the time already spent.

Write down why you make decisions as you make them. The code records what you did. Nothing records why, unless you do it yourself. Future you — and future colleagues — will not be able to reconstruct it.

The work becoming invisible is the goal. It means it worked. Try to make peace with that before the end, because the acknowledgement may not come from anywhere else.

For what it is worth: a couple of years after the migration completed, I was promoted to Staff Engineer — a level that did not exist at the company until then. I do not know exactly how much this project contributed to that. Probably it was one of several things. But it is a reminder that the work does register somewhere, even when it is not being talked about out loud.
