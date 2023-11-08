+++
title = "Moving to Kubernetes"
tags = ["replatform", "kubernetes"]
description = "Managing risk and setting a new baseline to improve on"
date = "2023-06-22T18:19:15Z"
+++

At work we are in the midst of moving away from our immutable infrastructure based on EC2, ASGs and Terraform to one that is our own mix of Kubernetes and some other extra tooling. The technique that we adopted to deploy this is a version of the Strangler Fig pattern.

# Strangling the http requests

This pattern talks about Event Interception. It does not suggest the exact mechanics of how this would work except that, whatever the implementation might be, it needs to be reversible. Reversibility sounds unncecessary, yet it helps reducing downtime caused by a subset of HTTP requests not handled correctly, and allows applying hot fixes to only one platform if the need comes.

The migration to Kubernetes for us was (and still is) a very long endeavour, and we had to reverse the course a few times, for both reasons highlighted in the previous paragraph.

Kubernetes has built-in way to manage load balancers. We preferred to not customize how load balancers are managed, therefore we opted to do interception at a different stage. We did that before the load balancer, using weights attached to our DNS records, along with short TTLs. This system turned out to be very effective for us.

![DNS weights in action](/attachments/http-requests-strangle.svg)

We use Terraform to create weighted DNS records. This is the pattern we use:

```
resource "aws_route53_record" "primary" {
  name    = <subdomain_string>

  set_identifier = "primary"

  weighted_routing_policy {
    weight = 100 - <weight>
  }

  alias {
    name                   = <k8s_load_balancer_dns_name>
  }
  ...
}

resource "aws_route53_record" "secondary" {
  name    = <subdomain_string>

  set_identifier = "secondary"

  weighted_routing_policy {
    weight = <weight>
  }

  alias {
    name                   = <ec2_load_balancer_dns_name>
  }
  ...
}
```

In order to do the above we had to disable external-dns on the domains we wanted to manage with weights.

# Strangling periodic processing

Cronjobs in Kubernetes have a dedicated crontroller. We decided to use that because it would allow us to get rid of any "cron.d" instance(s). Moving the scheduling to a centralized Kubernetes scheduler would also give us more precise and reliable scheduling, as each cronjob has dedicated cpu/memory for it.

We already had a distributed locking mechanism in place (using Memcache), and we decided to keep the same locking for all K8s cronjobs. Because the k8s scheduler is normally faster to launch than the Unix' cron.d, the "Event Interception" here is quite reliable: if a given cronjob is present in k8s, it will always acquire the lock. To reverse this, we simply remove it from the k8s list (see Day 2 as example)

![Cronjob locking](/attachments/cronjob-strangle.svg)

# Running (almost) the same thing

We deploy new code to production all the time, day and night. It is important that both platforms responds to events in the same way, and the way to achieve that is by running the same version and same configuration of our software. The constraint for us was to implement something that would force any artifact built from a specific commit to the master branch to be deployed in tandem to both EC2 and K8s.

## Slowing down new code release on Kubernetes

In our CI DAG, we have a step with 2 upstream dependencies

## Keeping versions of deployed code in sync
