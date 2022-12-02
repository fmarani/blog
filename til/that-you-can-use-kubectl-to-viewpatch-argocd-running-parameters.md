---
title: "That you can use kubectl to view/patch ArgoCD running parameters"
date: "2022-11-16T12:38:36+01:00"
tags: ["kubectl", "argocd"]
---
ArgoCD exposes its own set of K8s custom resources when installed on a cluster:

```
 k get crds
NAME                                         CREATED AT
applications.argoproj.io                     2022-08-09T14:24:40Z
applicationsets.argoproj.io                  2022-08-09T14:24:42Z
appprojects.argoproj.io                      2022-08-09T14:24:43Z
argocdextensions.argoproj.io                 2022-08-09T14:24:43Z
...
```

There is no need to install the argocd cli binary to interact with those. Kubectl is sufficient to visualize most of the information that would be available through the UI:

```
> k get apps
NAME            SYNC STATUS   HEALTH STATUS
cocoon-bridge   OutOfSync     Healthy
temper-sync     Synced        Healthy
kraken          OutOfSync     Healthy
envr-test       OutOfSync     Healthy

> k describe app cocoon-bridge
Name:         cocoon-bridge
...
Status:
  Conditions:
    Last Transition Time:  2022-11-16T11:22:05Z
    Message:               Any potential error message here
  Health:
    Status:  Healthy
  History:
    Deploy Started At:  2022-11-16T08:36:42Z
    Deployed At:        2022-11-16T08:36:42Z
    Id:                 1242
    Revision:           2844a3f7bfc264dffb0921e8b95350bf606de811
    Deploy Started At:  2022-11-16T09:54:52Z
    Deployed At:        2022-11-16T09:54:53Z
    Id:                 1243
  Reconciled At:          2022-11-16T12:00:39Z
  Sync:
    ...
    Status:               OutOfSync
Events:
...
```

You can also patch directly the application custom resource to change its parameters. Useful if you want to set an app to manual sync temporarily:

```
> k patch app cocoon-bridge --type merge --patch '{"spec": {"syncPolicy": null}}'
application.argoproj.io/cocoon-bridge patched
```
