+++
title = "How fixing the network for one client broke another one"
tags = ["outage", "networking", "bgp", "border gateway protocol"]
description = "Navigating through the gateways to find where route propagation broke"
date = "2023-05-02T19:19:15Z"
+++

At work we develop and release software to multiple clients, each one with their own set of AWS accounts. Normally these AWS accounts are owned by us but, for some specific clients, we just manage them. Last week one of our biggest customers, for which we manage the AWS account, suffered a network outage.

This was caused by a change to the way we advertise available routes to all our subnets, which ended up fixing the UK client and breaking the Australian client.

Here's a bit of background:

UK client
===
We own their AWS account, on which we have set up VPN connections with industry partners. Setting up these connections is a non-common and manual process mostly, where we communicate with the partners (or their network integrators) and let them know our requirements. We agree with them the routes that go through the gateway and those remain static.

Typically the partners have a low level of automation and sophistication, except in the security requirements, which are strict.

![What the UK network looks like](/attachments/client-uk-vpn.svg)

Australian client
===
We operate one of their AWS accounts, that they created for us after having set up the connection with their datacenter. This connection is to allow network traffic in both directions.

The datacenter to AWS connection has been done with AWS Direct Connect, which is a physical device that AWS has supplied to the DC facilities. This device is a Network Switch (with ethernet over fiber optics).

Each client of the datacenter has a VLAN number assigned, which is carried over the AWS connection. This creates one logical network that spans several physical segments.

This setup effectively removes any difference between AWS and local nodes: they are all VMs that can exchange traffic directly with each other.

Differently from the UK client, the VPN gateway sends and receives BGP route advertisements from/to the Datacenter. Routes are automatically updated when they change.

![What the AU network looks like](/attachments/client-au-bgp.svg)


The change
===
The change consisted in stopping advertising private subnets to partners (what in the diagrams is referred to as "VPN route propagation"). This is in preparation for a big overhaul of our private subnets, giving them 10x the number of IPs. The solution that we thought was to use the public subnet as an exit point, along with a NAT instance to do source IP translation (S-NAT) for the private subnet.

Most of our UK client's partners can only support hundreds of IPs, not thousands, like we are planning to. This made VPN route propagation on our private subnets side work against us. We had to remove these routes.

Unfortunately this broke all the connections between the private subnet and the Australian datacenter. As the NAT instance is a one-way forwarder, the traffic that was DC initiated could not target private subnets anymore.


Lessons learned
===
When you get to a point that you have dozens of clients, bespoke setups become more of a problem. It is also harder to recognize the problem if you are not aware of pre-existing infrastructure.

Finally, it is important to recognize that any change to such an important piece of your infrastructure, such as network routing, can have unintended consequences. Make sure everything is double checked.
