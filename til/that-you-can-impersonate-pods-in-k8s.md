---
title: "That you can impersonate pods in K8s"
Date: "2022-11-25T10:29:06+01:00"
tags: ["kubectl", "kubernetes", "rbac", "impersonation"]
---
Useful feature when you are developing against a cluster API is to act as the pod where your feature will be deployed.

In Kubernetes every pod is automatically assigned a service account. This is similar to any group on K8s, with the notable difference that service accounts are namespaced while built-in groups are not. If you do not have one specified, it falls back to `default`.

Let's take this simple deployment as example. It runs with the `system:serviceaccount:application:amazonmq-monitoring` service account.

```
> k describe deployment amazonmq-monitoring 
Name:                   amazonmq-monitoring
Namespace:              application
...
Pod Template:
  Service Account:  amazonmq-monitoring
...
```

To connect to the cluster API to read/write specific bits of data that only this serviceaccount is allowed to (via some RBAC rules) you can combine two tools: kubectl proxy and user impersonation.

`kubectl proxy` allows you to have a local proxy that forwards unauthenticated HTTP calls to a remote cluster, taking care of the authentication.

User impersonation is a feature that allows, post authentication, to change the acting user (or group) to something else. This is only possible if impersonation is allowed explicitly (or if your user is part of the `system:masters` group).

You combine the two features with `kubectl proxy --as system:serviceaccount:<namespace>:<serviceaccount>`:

```
> k proxy --as system:serviceaccount:application:amazonmq-monitoring
Starting to serve on 127.0.0.1:8001
...
```
