---
title: "How to route to all containers of a Docker host directly from LAN"
date: "2023-12-28T11:19:10+01:00"
tags: ["docker", "opnsense", "network", "routing"]
---

In its default configuration, a Linux machine running Docker runs containers in a dedicated virtual ethernet network that is bridged to the host network. Even with ports not bound to the host network interface, opened ports are still reachable through the bridge interface.

Given this network setup:
```
$ docker network ls
NETWORK ID     NAME      DRIVER    SCOPE
6e5b308632d5   bridge    bridge    local
2188eccd3f64   host      host      local
c5676813b035   none      null      local

$ docker network inspect bridge
[
    {
      ...
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "172.17.0.0/16",
                    "Gateway": "172.17.0.1"
                }
            ]
        },
        ...
        "Containers": {
            "d12ce6924eafd7740c8e0eef3138a796eda99c93b18ed285454e808eaed2a59d": {
                "Name": "web-test",
                "EndpointID": "d350eece0ef82b457d1ddbbba5b82df6c662a208c54dea05146665b02fe88787",
                "MacAddress": "02:42:ac:11:00:02",
                "IPv4Address": "172.17.0.2/16",
                "IPv6Address": ""
            }
        },
        ...
    }
]
```

We can reach that web-test container from the Docker host:

```
$ curl 172.17.0.2:8000
<pre>
Hello World


                                       ##         .
                                 ## ## ##        ==
                              ## ## ## ## ##    ===
                           /""""""""""""""""\___/ ===
                      ~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ===- ~~~
                           \______ o          _,/
                            \      \       _,'
                             `'--.._\..--''
</pre>
```

It is possible to reach this `172.17.0.0/16` network from the local area network if IP forwarding is enabled on the Docker host and the right network routes are active on the main LAN router.

Enable IP forwarding
---

IP forwarding on a Docker host is slightly non-standard, because of the way Docker uses the forward chain. The following two commands are enough to make Docker bridge reachable by incoming traffic.

```
# watch out the below commands do not make the change permanent

$ echo 1 > /proc/sys/net/ipv4/ip_forward
$ iptables -I DOCKER-USER -i <src_if> -j ACCEPT
```

Substitute `<src_if>` with the name of the network interface where the traffic is flowing in,  which is usually eth0. More info on the iptables command is available [here](https://docs.docker.com/network/packet-filtering-firewalls/#docker-on-a-router).

LAN level routing
---

This step is dependent on whatever you use in your LAN. If your router does not support adding static routes, I am not aware of a solution that works with a single Docker bridge. You'd need to be looking at some software to announce IPs via ARP (like what MetalLB does [here](https://metallb.universe.tf/concepts/layer2/)).

At home I am using OPNSense, which allows customizing static routes. You do that by first adding a single gateway:

![Single gateway on OPNSense](/attachments/opnsense-gw-dockerbridge.jpg)

The only important bit in the above screenshot is the Gateway IP, which must be set to the IP of the Docker host.

![Docker route on OPNSense](/attachments/opnsense-route-dockerbridge.jpg)

With the Gateway created, a static route can be associated. That route would be to the `172.17.0.0/16` network, or to a section of it.

Once the route configuration is saved and applied, the router itself will be able to connect to the Docker container, on the opened port 8000.

The choice now is to either to open this route at the firewall level by inserting some ALLOW rules, or to proxy the connection through a OPNSense managed load balancer (e.g. Nginx). Once you have done one of the two things, every computer will be able to connect.
