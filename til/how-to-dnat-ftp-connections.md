---
title: "How to DNAT FTP connections"
date: "2023-10-02T17:27:48+02:00"
tags: ["ftp", "nat", "network", "iptables"]
---

Let's consider the scenario of a NAT server doing the forwarding between an internal network and internet, and a client that sits in the internal network which runs the ftp client. To simulate this, we can use network namespaces.

We will use the root namespace as the NAT server, and create a dedicated network namespace for the client.

```
ip netns add client
```

Peering these namespaces with a pair of configured virtual eth interfaces, one of them in the client ns and one in the root ns:

```
ip link add eth0 netns client type veth peer name eth0

ip netns exec client ip addr add 192.168.5.1/24 dev eth0
ip netns exec client ip link set eth0 up

ip addr add 192.168.5.2/24 dev eth0
ip link set eth0 up
```

With the above we created one `eth0`, scoped to the client, with an IP of `192.168.5.1`, and another `eth0`, scoped to the NAT server, with `192.168.5.2`.

Quick test to make sure the interfaces are pingable:

```
> ping 192.168.5.1
PING 192.168.5.1 (192.168.5.1) 56(84) bytes of data.
64 bytes from 192.168.5.1: icmp_seq=1 ttl=64 time=0.168 ms
64 bytes from 192.168.5.1: icmp_seq=2 ttl=64 time=0.109 ms
64 bytes from 192.168.5.1: icmp_seq=3 ttl=64 time=0.092 ms
^C
--- 192.168.5.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2034ms
rtt min/avg/max/mdev = 0.092/0.123/0.168/0.032 ms

> ip netns exec client ping 192.168.5.2
PING 192.168.5.2 (192.168.5.2) 56(84) bytes of data.
64 bytes from 192.168.5.2: icmp_seq=1 ttl=64 time=0.131 ms
64 bytes from 192.168.5.2: icmp_seq=2 ttl=64 time=0.114 ms
64 bytes from 192.168.5.2: icmp_seq=3 ttl=64 time=0.117 ms
^C
--- 192.168.5.2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2042ms
rtt min/avg/max/mdev = 0.114/0.120/0.131/0.007 ms
```

Now the fun part. NAT server needs to forward FTP traffic. 

FTP traffic is difficult to forward: active mode cannot be NATted, because it requires both parties having public IPs. Passive mode can be NATted, but needs extra care.

When people refer to NAT, they most likely refer to SNAT. SNAT (Source NAT) is a network change that is a lot more invasive than DNAT (Destination NAT). For SNAT to work, all computers within the internal network have to have the NAT box IP as a route.

DNAT only requires changing the FTP destination IP, which is likely just an application configuration change. The FTP client will be unaware of the real destination, it will connect to the NAT server's port 2121.

First of all, to enable any form of NAT, we must first enable IP forwarding:

```
> echo 1 > /proc/sys/net/ipv4/ip_forward
> iptables -A FORWARD -s 192.168.5.1 -i eth0 -j ACCEPT
```

Then DNAT every possible port. That's because there's no standard passive port range, and we do not know if the server is limiting the passive port range.

```
> iptables -t nat -A PREROUTING -p TCP -i eth0 -j DNAT --to-destination 209.132.178.32  # that's RedHat public ftp server, used as example
> iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE  # enp0s3 is NAT server's outgoing interface
```

Now you can see FTP connections working, more or less:

```
> ip netns exec client lftp 192.168.5.2

lftp 192.168.5.2:/> debug
lftp 192.168.5.2:/> ls pub
---> PASV
<--- 227 Entering Passive Mode (209,132,178,32,54,198)
---- Address returned by PASV seemed to be incorrect and has been fixed
---- Connecting data socket to (192.168.5.2) port 14022
---- Data connection established           
---> LIST pub
<--- 150 Here comes the directory listing.
---- Got EOF on data connection
---- Closing data socket
lrwxrwxrwx    1 ftp      ftp             1 Dec 19  2009 pub -> .
drwxr-xr-x   37 ftp      ftp          4096 Aug 31 05:47 redhat
drwxr-xr-x    3 ftp      ftp          4096 Sep 10  2019 suse
<--- 226 Directory send OK.
---- Closing idle connection
```

The reason for the "Address returned by PASV seemed to be incorrect and has been fixed" is because there's no ftp connection tracking. The LFTP client is smart enough to ignore it, but not all clients do that. 

Let's add conntrack support and activate that on the NAT server's inbound interface, port 2121:

```
> modprobe nf_conntrack_ftp  # this keeps track of PORT and PASV commands
> modprobe nf_nat_ftp        # this does the rewriting of PORT commands
> iptables -A PREROUTING -t raw -p tcp -i eth0 --dport 2121 -j CT --helper ftp  # this enables the conntracker on port 2121
```

Now we can make the DNAT rule more precise, targeting a specific destination port. Differently than before, the DNAT now only targets the FTP control connection port, and not anymore any possible data connection port. The data connection is under conntrack now, and rewritten by the NAT FTP module.

```
> iptables -t nat -D PREROUTING -p TCP -i eth0 -j DNAT --to-destination 209.132.178.32  # remove the generic DNAT rule added before
> iptables -t nat -A PREROUTING -p TCP -i eth0 --dport 2121 -j DNAT --to-destination 209.132.178.32:21  # add a DNAT rule with ports specified
```

Test:

```
> ip netns exec client lftp 192.168.5.2:2121
lftp 192.168.5.2:~> debug
lftp 192.168.5.2:~> ls
...
---> PASV
<--- 227 Entering Passive Mode (192,168,5,2,55,168)
---- Connecting data socket to (192.168.5.2) port 14248
---- Data connection established
---> LIST
<--- 150 Here comes the directory listing.
---- Got EOF on data connection
---- Closing data socket
lrwxrwxrwx    1 ftp      ftp             1 Dec 19  2009 pub -> .
drwxr-xr-x   37 ftp      ftp          4096 Aug 31 05:47 redhat
drwxr-xr-x    3 ftp      ftp          4096 Sep 10  2019 suse
<--- 226 Directory send OK.
```

No address error anymore. This setup should now work with every client, as long as the FTP server supports PASV or EPSV mode.
