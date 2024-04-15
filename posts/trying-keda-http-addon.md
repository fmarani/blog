+++
title = "Trying KEDA HTTP addon"
tags = ["keda", "kubernetes"]
description = "Exploring how it builds on top of KEDA and testing how it performs"
date = "2024-04-02T18:19:15Z"
+++

At work we do lots of HTTP based scaling for our pods. That is because the workloads we run are mostly I/O bound, primarily waiting for queries to databases: cpu and memory usage do not grow by much when HTTP traffic increases, they are not representative metrics to scale on.

At the moment we use Prometheus exporters in the http server pod that KEDA can read, but that has a few problems:
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

The HTTP addon generates automatically a `ScaledObject`:

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

Benchmark
---

To test the addon, I have run a copy of [podinfo](https://github.com/stefanprodan/podinfo) as it comes in the chart. On top of that, I have added a couple of resources:

```yaml
kind: HTTPScaledObject
apiVersion: http.keda.sh/v1alpha1
metadata:
    name: podinfo
spec:
    hosts:
      - podinfo-proxy
    targetPendingRequests: 10
    scaleTargetRef:
        name: podinfo
        kind: Deployment
        apiVersion: apps/v1
        service: podinfo
        port: 9898
    replicas:
        min: 0
        max: 10
---
apiVersion: v1
kind: Service
metadata:
  name: podinfo-proxy
spec:
  externalName: keda-add-ons-http-interceptor-proxy.keda.svc.cluster.local
  type: ExternalName
```

Podinfo should now scale linearly with concurrent requests: each block of 10 will cause a new pod to be created. The externalName service is needed to make sure that HTTP requests get the right HTTP Host header. The Service name must match the one of the hosts in the HTTPScaledObject list.

To test this I have created an Ubuntu pod:

```
> kubectl apply -f << EOF
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu
  labels:
    app: ubuntu
spec:
  containers:
  - image: ubuntu
    command:
      - "sleep"
      - "11200"
    imagePullPolicy: IfNotPresent
    name: ubuntu
  restartPolicy: Never
EOF
> kubectl exec -it ubuntu -- bash
...install apache2-utils...
> ab -n 200 -c 5 http://podinfo-proxy:8080/chunked/1  # please note port 8080, that is the listen port of http-interceptor-proxy
...this should start one podinfo pod...
```

I have run `ab` with several values:

1000 requests, with 20 concurrent, forcing 1 second slow responses, causes the autoscaler to ramp up to 2 replicas:
```
> kubectl get hpa keda-hpa-podinfo -w
NAME               REFERENCE            TARGETS               MINPODS   MAXPODS   REPLICAS   AGE
keda-hpa-podinfo   Deployment/podinfo   <unknown>/10 (avg)    1         10        0          3d1h
keda-hpa-podinfo   Deployment/podinfo   20/10 (avg)           1         10        1          3d1h
keda-hpa-podinfo   Deployment/podinfo   9500m/10 (avg)        1         10        2          3d1h
keda-hpa-podinfo   Deployment/podinfo   10/10 (avg)           1         10        2          3d1h
keda-hpa-podinfo   Deployment/podinfo   9500m/10 (avg)        1         10        2          3d1h
...
```

Same parameters but a concurrency of 60 causes ramp up to 6:
```
keda-hpa-podinfo   Deployment/podinfo   <unknown>/10 (avg)    1         10        0          3d1h
keda-hpa-podinfo   Deployment/podinfo   60/10 (avg)           1         10        1          3d1h
keda-hpa-podinfo   Deployment/podinfo   15/10 (avg)           1         10        4          3d1h
keda-hpa-podinfo   Deployment/podinfo   9/10 (avg)            1         10        6          3d1h

```

Now with 5000 requests and a concurrency of 110, which causes the autoscaler to max out at 10, as instructed in the HTTPScaledObject:
```
keda-hpa-podinfo   Deployment/podinfo   110/10 (avg)          1         10        1          3d1h
keda-hpa-podinfo   Deployment/podinfo   27500m/10 (avg)       1         10        4          3d1h
keda-hpa-podinfo   Deployment/podinfo   13750m/10 (avg)       1         10        8          3d1h
keda-hpa-podinfo   Deployment/podinfo   11/10 (avg)           1         10        10         3d1h
```
