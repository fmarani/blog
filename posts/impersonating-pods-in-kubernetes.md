+++
title = "Impersonating pods in Kubernetes"
tags = ["kubernetes"]
date = "2022-11-24T19:41:15Z"
+++
Useful feature when you are developing against a cluster APIs is to act as the pod where your feature will be deployed. In Kubernetes every pod is automatically assigned a service account, and this is no different from any group on K8s.

Kubernetes allows you to do that with 
