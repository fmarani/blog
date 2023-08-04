---
title: "AWS throttles DNS requests to the VPC resolver"
date: "2023-08-04T16:55:35+02:00"
tags: ["kubernetes", "aws", "eks"]
---

At work we use CoreDNS to forward queries to the VPC resolver, as we run most of our services in Kubernetes. What that means is that we are routing all DNS queries through a few machines, and we recently discovered the risks in doing that.

The AWS network plane has high limits, but it is still capped. DNS requests are normally 1 packet long. ENIs are capped at 1024 packets per second, which means you cannot send more than 1024 DNS requests per second, in the best scenario.

It is possible to read metrics about how frequently this throttling happens by accessing the registers of the ENA network driver. You can do that directly from the worker node.

```
# ethtool -S eth0 | grep allowance
     bw_in_allowance_exceeded: 9
     bw_out_allowance_exceeded: 0
     pps_allowance_exceeded: 0
     conntrack_allowance_exceeded: 0
     linklocal_allowance_exceeded: 0
     conntrack_allowance_available: 601984
```

You can also do that from a pod if:
- it runs on the [host network](https://kubesec.io/basics/spec-hostnetwork/)
- has [CAP_NET_ADMIN](https://man7.org/linux/man-pages/man7/capabilities.7.html) capability

which is a non-standard configuration for the average pod. This is what this special manifest could look like:

```
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: agent
spec:
  template:
    spec:
      containers:
      - command:
        - agent
        - run
        securityContext:
          capabilities:
            add:
            - NET_ADMIN
      ...
      hostNetwork: true
      ...
```
