---
title: "You cannot restrict pod/exec permission to subsets of pods in a namespace"
date: "2023-01-31T12:25:55+01:00"
tags: ["kubernetes", "rbac"]
---

While it is possible to craft a role using wildcards in the resource names, it will not work to restrict pod/exec permissions. Let's test this:

Let's start with some basic RBAC rules and one namespace:

```sh
> kubectl create namespace testns
namespace/testns created

> cat perm-view.yaml 
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: pod-view
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: pv-bind
subjects:
- kind: User
  name: myuser
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-view

> kubectl apply -f perm-view.yaml -n testns
role.rbac.authorization.k8s.io/pod-view unchanged
rolebinding.rbac.authorization.k8s.io/pv-bind created
```

And the exec permission, limited to a pattern:

```sh
> cat perm-exec.yaml 
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: exec
rules:
- apiGroups: [""]
  resources: ["pods/exec"]
  resourceNames: ["services-*"]
  verbs: ["create"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: exec-bind
subjects:
- kind: User
  name: myuser
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: exec

> kubectl apply -f perm-exec.yaml -n testns
role.rbac.authorization.k8s.io/exec created
rolebinding.rbac.authorization.k8s.io/exec-bind created
```

Now that we have the basic role in place, let's run a shellable pod with a matching name:

```sh
> kubectl run services-busybox --image=busybox --restart=Never -n testns -- sh -c "sleep infinity"
pod/services-busybox created
```

If we exec with a master user, no problem:

```sh
> kubectl exec -n testns -it services-busybox -- sh
/ #
/ # whoami
root
/ # exit
```

If we exec with the user myuser, for which the exec should have granted exec access we can see it is not working:

```sh
> kubectl exec -n testns --as myuser -it services-busybox -- sh
Error from server (Forbidden): pods "services-busybox" is forbidden: User "myuser" cannot create resource "pods/exec" in API group "" in the namespace "testns"
```
