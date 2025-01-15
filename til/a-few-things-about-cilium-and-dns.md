---
title: "A few things about Cilium and DNS"
date: "2025-01-15T10:17:38+01:00"
tags: ["kubernetes", "cilium", "dns"]
---

Some learnings from the webinar I attended yesterday:

FQDN, PQDN, hostnames and root zones
---

You can tell the DNS resolver to not traverse the search path if you explicitly put a full stop "." at the end of a FQDN. That tells the resolver the FQDN is specified up until the root zone. Not traversing the search path, for a standard EKS setup, means generating 4-5 times less DNS traffic. That has a big impact, especially on services that connect to external endpoints with low DNS TTLs.

musl libc and glibc resolvers are different
---

musl libc, in use in Alpine images, ignored ndots and search paths for a long time. Now they use it, but the behaviour is not the same as glibc, especially around NXDOMAIN codes (returned when a domain does not exist).


Multiple CoreDNS deployments
---

You can have more than one CoreDNS deployment per cluster, and configure them differently if you want them to.


`cilium fqdn cache` commands
---

Those commands can be used on the Cilium agent to check the state of Cilium DNS proxy, and to reset it if needed.


Hubble Enterprise policy suggestions
---

This version of Hubble has the ability to suggest policy changes on dropped traffic, in case we would like to change it to allow. The suggestion will not auto-apply, but rather can be used to create a Github PR.
