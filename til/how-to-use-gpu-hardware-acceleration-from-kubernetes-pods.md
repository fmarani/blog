---
title: "How to use GPU hardware acceleration from Kubernetes pods"
date: "2025-04-11T09:41:23+02:00"
tags: ["kubernetes", "hex"]
---

I have been slowly migrating the containers in my homelab to kubernetes, and recently I have done Frigate. [Frigate](https://frigate.video/) is not a standard container, it requires a few extra features to run. Internally it relies a lot on FFmpeg, which can use GPU hardware acceleration for encoding/decoding videos.

In Linux, you can access GPUs through the [DRI](https://en.wikipedia.org/wiki/Direct_Rendering_Infrastructure) interface. Those entries are available through the usual dev folder:

```
> ls /dev/dri
by-path  card0  renderD128
> udevadm info /dev/dri/renderD128
P: /devices/pci0000:00/0000:00:02.0/drm/renderD128
...
> lspci -s 00:02.0
00:02.0 VGA compatible controller: Intel Corporation Xeon E3-1200 v3/4th Gen Core Processor Integrated Graphics Controller (rev 06)
```

Normally you would be able to access those from the user-space by just being root, and you can do that from containers too. 

This is the deployment I have used:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frigate
  namespace: home-automation
spec:
  selector:
    matchLabels:
      app: frigate
  template:
    metadata:
      labels:
        app: frigate
    spec:
      containers:
      - image: ghcr.io/blakeblackshear/frigate:stable
        imagePullPolicy: IfNotPresent
        name: frigate
        ports:
        - containerPort: 5000
          name: web
          protocol: TCP
        securityContext:
          privileged: true
        volumeMounts:
        - mountPath: /dev/dri/renderD128
          name: renderd128
        ...
      nodeSelector:
        kubernetes.io/hostname: sauron
      volumes:
      - hostPath:
          path: /dev/dri/renderD128
          type: CharDevice
        name: renderd128
        ...
```

The important bits are:
- `privileged: true`: runs it without any container isolation. It has complete access to Linux capabilities.
- `nodeSelector`: need to make sure the pod only runs on the server where this specific PCI card is attached to.
- `hostPath: /dev/dri/...`: exposes this PCI device to Frigate. I also used the `type: CharDevice` although in practice I don't think that makes it much difference.

