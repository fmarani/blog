---
title: "DNS resolutions inside a VPC only uses the most specific Route53 zone"
date: "2025-10-11T14:52:06+02:00"
tags: ["aws", "route53", "network", "dns"]
---

If you have multiple DNS entries for the same host, spread on different zones on Route53, resolutions only consider the zone that maches with the highest number of DNS levels.

For instance, let's say you have `fede.test.something.com` defined twice, in the public zone `something.com` and in the private zone `test.something.com`.

![public zone definition](/attachments/dns-resolutions-2.png)
![private zone definition](/attachments/dns-resolutions-3.png)

Given that resolutions inside the VPC consider both public and private zones, if you try looking up that domain, you get the entry from the most specific zone, the private one.

![resolution from outside the VPC](/attachments/dns-resolutions-5.png)
![resolution from inside the VPC](/attachments/dns-resolutions-6.png)

What I learned is that if you remove the domain entry in the private zone, without removing the zone itself, it will not fallback to the public zone. It will just fail resolution.

![resolution from inside failure](/attachments/dns-resolutions-7.png)

It will only start working again if you remove the zone too, or reassign it to a different VPC, in which case it will use the only remaining zone, which is the main public one.

![resolution from inside the VPC](/attachments/dns-resolutions-1.png)
