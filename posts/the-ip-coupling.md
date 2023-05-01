+++
title = "The IP coupling"
tags = ["ip"]
date = "2023-04-23T19:19:15Z"
+++

Many integrations with 3rd party APIs that we do at work have a networking component. Sometimes it comes in the shape of a VPN, sometimes allow-listing our NAT boxes: we do hide a big chunk of our outgoing traffic behind a few public IP addresses, but sometimes our partners force us to do further tunnelling (e.g. IPSec).

Both network setups have a problem of coupling. Our code does not work anymore if not within a certain network layout. Is there a way to decouple IPs from code?

What's good about IPs is that they are a lot harder to reuse. In case of credentials leak, any actor that gets in possession of those can act as us but, to impersonate us with our IP, you would have to hack into the network and gather enough permissions to create a proxy to bounce off your traffic. It is more complicated. The alternative is to go up the chain and hack the organization that allocates IP ranges, which sounds quite impractical.

Is there an identification method that, as soon as it is stolen by a hacker, becomes useless?


Hierarchies of trust
===

IP ranges
--

IP ranges are allocated by a global entity called [IANA](https://en.wikipedia.org/wiki/Internet_Assigned_Numbers_Authority), which divides IP management among a number of organizations based on world geography.

![IP allocation structure](/attachments/ip-allocation-structure.svg)
![IP allocation structure](/attachments/rir-world-map.svg)

Network topology authentication works so well because it anchors itself to the geography. Also, although the various ASN are in fact autonomously organized, IP block change advertisements are signed with a PKI infrastructure, therefore secure by default.

DNS
---

DNS is another hierarchical system. Names are also handed out by a global entity (ICANN) and then, as we go up the hierarchy, we have country registers and then private registers. While technically it is possible to substitute IP coupling with a DNS coupling (either by A records or PTR), it is not very commonly used. One of the reasons is that DNS is not a very secure protocol: it is clear text and easily spoofable. DNS-over-HTTPS may change things on this front, but it is still not wide-spread.

Another problem with DNS is that it can only be used to map names to single IPs, not IP ranges.

Certificate Authorities
---
d


Zero trust
===

d
