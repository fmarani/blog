---
title: "How to test weighted DNS A records"
date: "2023-03-01T23:49:49+01:00"
tags: ["dns"]
---

On Route53 you can configure record sets with associated weights as A records.

![weighted a records](/attachments/weighted-a-records.png)

To test that the above weights translate in the right resolutions, we need to start from the authoritative server. Here's a bit of commands to test this (in fish shell):

```fish
> set authoritative (string split " " -- (dig octopus.energy NS +short))[1]
> for i in (seq 1 100)
    dig octopus.energy A @$authoritative +short >> auth_resolutions.txt
  end
> cat auth_resolutions.txt | sort | uniq -c
 99 34.242.168.145
  1 34.246.144.170
 99 34.248.251.0
  1 34.255.175.52
```

The output shows it as working. The IPs are 4 because of the number of AZs we use.

DNS records are propagated to recursive resolvers with a TTL. Ours is set to 60 seconds, to make sure we are able to propagate weighting changes as quickly as possible.

