+++
title = "Trying KEDA HTTP addon"
tags = ["keda", "kubernetes"]
description = "Using for loops to generate lightly customized resources"
date = "2024-04-02T18:19:15Z"
+++

At work we do lots of HTTP based scaling for our pods. That is because the workloads we run are mostly i/o bound, primarily waiting for queries to databases: cpu and memory usage do not grow by much when HTTP traffic increases, they are not representative metrics to scale on.

At the moment we use Prometheus exporters that KEDA can read, but that has a few problems:
- http connection buffering happens on the pod that do http processing, which makes it susceptible to connection drop in case the pod is terminated
- forces us to run lots of containers in one pod, which need custom configurations
- if Prometheus is unavailable, our scaling is unavailable
- cannot scale to zero

There are not many open source projects that I am aware of that can offer scaling based on HTTP inbound traffic. KNative is the most known, but it does not seem easy to integrate with our current deployments. That is why I was keen to try the KEDA HTTP addon. We are already heavy users of KEDA, and the addon builds on top of concepts we are very familiar with.

The HTTP addon adds a new custom resource, HTTPScaledObejct, with this structure:

```yaml
kind: HTTPScaledObject
apiVersion: http.keda.sh/v1alpha1
metadata:
    name: testdeployment
spec:
    hosts:
      - example.com
    targetPendingRequests: 16
    scaleTargetRef:
        name: testdeployment
        kind: Deployment
        apiVersion: apps/v1
        service: testsvc
        port: 8080
    replicas:
        min: 0
        max: 10
```

If the above resource was deployed on the cluster, all inbound requests with the hostname `example.com` that reach the http-interceptor-proxy service (the entry point for all http scaled objects) will be proxyed to `testsvc` at port `8080`. If at any point, the number of concurrent requests reaches 16, it will scale up the deployment `testdeployment` to 2 replicas.

The HTTP addon underneath generates automatically a `ScaledObject`:

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: testdeployment
spec:
  maxReplicaCount: 10
  minReplicaCount: 0
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: testdeployment
  triggers:
  - type: external-push
    metadata:
      hosts: example.com
      pathPrefixes: ""
      scalerAddress: keda-add-ons-http-external-scaler.keda:9090
```

The http-interceptor-proxy and the http-external-scaler component are how this addon works. One holds the connection open until the proxying happens, the other pushes concurrency metrics to KEDA to enact scaling or not.

![How the HTTP addon integrates with inbound and scaling](/attachments/keda-http-addon.svg)

The interceptor proxy and external scaler components can serve many different services/deployments. The cost of adding one HTTPScaledObject or many is the same.
