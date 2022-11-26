+++
title = "Difference between env and envFrom in Kubernetes deployments"
tags = ["kubernetes"]
date = "2022-11-16T15:41:15Z"
+++

When deploying software on Kubernetes, it is common to inject configuration parameters using environment variables. It is one of the ideas that Heroku advocated for so long, with the 12 factor app manifesto, and it is now common practice. On Kubernetes there are several ways to do that.

Let's take this Deployment as reference

```
> k get deployment coreworker -o yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coreworker
spec:
...
  template:
    metadata:
      annotations:
        env.coreworker/checksum: cce0fe17
    spec:
      containers:
      - args:
        - worker
        command:
        - celery
        env:
        - name: DD_ENV
          value: test
        - name: DD_SERVICE
          value: core
        - name: DJANGO_CONFIGURATION
          value: Worker
        - name: POD_IP
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: status.podIP
        - name: HOSTNAME
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.name
        envFrom:
        - configMapRef:
            name: coreworker-environment
        - secretRef:
            name: coreworker-environment
        image: django:62613
        name: django
```

You can see the two distinct methods above: `env` and `envFrom`. They both help you achieve the same thing, which is make data available to the application, but from a Kubernetes perspective, they are very different.

# `env` sections

This is the most obvious way to inject configuration data. It is very easy to spot, and very easy to verify what is injected. Any change to their value will cause a manifest change, which in turn causes K8s to rotate the replicasets, which restarts the app with the new value.

This way to specify variables is also the easiest way to use the Downward API, used to inject dynamic data from the cluster into the deployment. Here you can see `POD_IP` passed to the application, which contains the IP that the networking layer assigned to the pod.

In cases in which your app requires a lot of configuration data, this can get unwieldy. This method does not work well for long sets of variables. 

# `envFrom` sections

These sections are used to refer to environment variables that are either specified in a ConfigMap or a Secret manifest. The manifest above references both a ConfigMap (used more liberally for key/value pairs) and a Secret.

```
> k get cm coreworker-environment -o yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coreworker-environment
data:
  ENVIRONMENT: test
  DB_URL: databases.company/name
  LOGGING: "1"
  ...
```

The Secret would have the same structure.

The advantage of using external references, besides being better for long list of variables, is that, being a separate K8s resource, different RBAC rules can apply. You may want to be more liberal about Deployment read access, but stricter on reading the content of a Secret manifest, limiting that to only a few people in the business.

The disadvantage of external references is that, when updated, they do not propagate changes automatically, or trigger a restart of the pod. To force this, our Deployment manifest needs something that varies in the YAML.

One of the conventions that Helm encourages is to include a [configuration checksum as annotation](https://helm.sh/docs/howto/charts_tips_and_tricks/#automatically-roll-deployments) in the deployment. It is a way of telling Kubernetes that any configuration change needs to trigger an application restart. Another way could be to dynamically change the ConfigMap name, appending a random suffix. 

Kubernetes does not offer a standard way to solve this (more details [here](https://github.com/kubernetes/kubernetes/issues/22368)), and each deployment tool ended up solving this problem in a different way.
