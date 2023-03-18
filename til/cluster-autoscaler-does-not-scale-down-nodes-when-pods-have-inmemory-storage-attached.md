---
title: "Cluster autoscaler does not scale down nodes when pods have in-memory storage attached"
date: "2023-03-18T11:53:16+01:00"
tags: ["kubernetes", "cluster autoscaler", "scaling"]
---

In some of our pods we use a temporary storage, to exchange data between the containers that belong to the same pod.

```
> k describe pod customersite
.......
Volumes:
...
  sockets:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:     Memory
    SizeLimit:  <unset>
...
```

This innocuous practice caused us to find out that lots of nodes were kept around even though they could have been shut down.

Cluster autoscaler is, by default, configured to scale down nodes that have low utilization. If a node is under-used, it becomes a candidate for removal but, to be removable, each pod running on it needs to be safe to evict (that's [one](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#what-types-of-pods-can-prevent-ca-from-removing-a-node) of the criteria).

Pods with local storage are by default not safe to evict. Temporary in-memory storage is considered local storage, even though in our case there's nothing important on it: the autoscaler consider this pod untouchable. There's a [ticket](https://github.com/kubernetes/autoscaler/issues/2048) on Github that confirms this.

You can verify this in the cluster autoscaler pod logs:

```
❯ kubectl -n kube-system logs pod/cluster-autoscaler-aws-cluster-autoscaler-55858454bf-6b9vd | grep 'cannot be removed'
...
Fast evaluation: node ip-10-2-211-144.ap-southeast-2.compute.internal cannot be removed: pod with local storage present: customersite-5db7788c87-gkrqs
Fast evaluation: node ip-10-2-206-28.ap-southeast-2.compute.internal cannot be removed: pod with local storage present: customersite-7bc5dd45c5-qw5vd
...
```

Adding the annotation `"cluster-autoscaler.kubernetes.io/safe-to-evict": "true"` solved the problem for us:

```
❯ kubectl -n application describe pod/customersite-57fbccd59c-9c6h2
Name:             customersite-57fbccd59c-9c6h2
Namespace:        application
Labels:           app.kubernetes.io/instance=...
                  app.kubernetes.io/name=...
Annotations:      cluster-autoscaler.kubernetes.io/safe-to-evict: true
...
```
