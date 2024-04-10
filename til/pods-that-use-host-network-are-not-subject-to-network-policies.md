---
title: "Pods that use host network are not subject to network policies"
date: "2024-04-10T15:04:18+02:00"
tags: []
---

In Cilium, if a pod runs with the hostNetwork set to true, it will run with the same IP of the host. Such pods runs unrestricted, without policy enforcement by default. That is because those pods do not get an associated CiliumEndpoint entity created, which is the thing that policies are executed against.

```
> k get pod podname -o yaml | grep hostNet
  hostNetwork: true

> k get ciliumendpoint podname
Error from server (NotFound): ciliumendpoints.cilium.io "podname" not found
```

Normal pods do get an endpoint:
```
> k get pod standardpod -o yaml | grep hostNet
> k get ciliumendpoint standardpod
NAME          ENDPOINT ID   IDENTITY ID   INGRESS ENFORCEMENT   EGRESS ENFORCEMENT   VISIBILITY POLICY   ENDPOINT STATE   IPV4          IPV6
standardpod   1525          12091         <status disabled>     <status disabled>    <status disabled>   ready            10.0.107.65
```

Any policy rule on them are not applied, and consequently nothing is displayed in Hubble about those pods.
