---
title: "How to use /dev/shm from Kubernetes pods"
date: "2025-04-22T22:29:16+02:00"
tags: ["kubernetes", "hex"]
---

Following up from [this](/til/how-to-use-gpu-hardware-acceleration-from-kubernetes-pods/), I also had to add `/dev/shm` to Frigate. A SHM device is simply a temporary filesystem which uses RAM as a storage instead of a persistent storage.

In a pod definition this is how it looks like:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frigate
  ...
spec:
  ...
  template:
    ...
    spec:
      containers:
      - image: ghcr.io/blakeblackshear/frigate:stable
        imagePullPolicy: IfNotPresent
        name: frigate
        ...
        volumeMounts:
        - mountPath: /dev/shm
          name: dev-shm
        ...
      volumes:
      - emptyDir:
          medium: Memory
          sizeLimit: "67108864"
        name: dev-shm
        ...
```

The specific path `/dev/shm` is more of a convention rather than having a special meaning. There is no need to remap host's `/dev/shm` to the pod as the sharing of it makes sense only within the pod itself.

Kubernetes offer emptyDir volumes which normally would be mapped to a temporary device but persisted, but by specifying `medium: Memory` they can be stored in RAM. `sizeLimit` is the limit in bytes of such volume.
