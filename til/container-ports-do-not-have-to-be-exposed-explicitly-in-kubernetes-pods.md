---
title: "Container ports do not have to be exposed explicitly in Kubernetes pods"
date: "2023-11-08T12:40:33+01:00"
tags: ["kubernetes", "networking"]
---

All containers that are part of a pod have the same network namespace, and (can) bind to all IPs in that namespace. Kubernetes does not offer any implicit filtering between pod network namespace and what is exposed at the network level. If a container binds to a port in the pod, that port is reachable at cluster-level[^1].

Let's take this pod as reference:

```
> k describe pod instancename-appname-64d7cc857f-ffzmk
...
Node:                 ip-10-1-54-136.eu-west-3.compute.internal/10.1.54.136
Status:               Running
IP:                   10.1.50.84
Containers:
  nginx:
    Image:          ...
    Port:           80/TCP
    Host Port:      0/TCP
    ...
```

Our Nginx listens to multiple ports, but only some are advertised in the pod description. The port list above is purely informational. It does not exclude any port not listed there from being accessed.

We can test this from another pod:

```
$ curl -I 10.1.50.84:8000
HTTP/1.1 301 Moved Permanently
Server: nginx
Date: Wed, 08 Nov 2023 12:02:22 GMT
Content-Type: text/html
Content-Length: 162
Connection: keep-alive
Location: https://10.1.50.84/
```

This lack of filtering is useful in case containers need to open connections between each other, but without advertising it in the manifest.

[^1]: only if the CNI is configured to allow pod-to-pod connectivity
