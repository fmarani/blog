---
title: "How to include AWS-specific info when using kubectl get nodes"
date: "2022-11-12T16:02:19+01:00"
tags: ["eks", "kubernetes", "kubectl"]
---

The standard configuration when using `kubectl get nodes` is meant to be working for any cluster, therefore does not include any specific information about the K8s distribution you are using. 

At work we are big users of AWS, and we are running many EKS clusters. Clusters with multiple nodegroups, each one with different launch templates which brings nodes up with different security groups attached.

Sometimes it is difficult to print all this information. `kubectl` has a `custom-columns` output that is helpful in the case you want to print AWS specific information. Here's an example:


```
> k get nodes -o custom-columns=NAME:.metadata.name,INSTANCE_TYPE:".metadata.labels.node\.kubernetes\.io/instance-type",EKS_NODEGROUP:".metadata.labels.eks\.amazonaws\.com/nodegroup",READY:".status.conditions[?(@.reason=='KubeletReady')].status",CREATED_AT:".metadata.creationTimestamp"

NAME                                            INSTANCE_TYPE   EKS_NODEGROUP                              READY   CREATED_AT
ip-10-0-115-000.eu-central-1.compute.internal   m5.2xlarge      br_privileged-20220525160725365900000001   True    2022-11-12T11:06:45Z
ip-10-0-116-000.eu-central-1.compute.internal   m5.large        br_default-20220525160725393100000003      True    2022-11-07T10:31:33Z
ip-10-0-118-00.eu-central-1.compute.internal    m5.large        br_default-20220525160725393100000003      True    2022-05-25T16:08:34Z
ip-10-0-119-000.eu-central-1.compute.internal   m5.2xlarge      br_privileged-20220525160725365900000001   True    2022-11-12T10:37:09Z
ip-10-0-124-000.eu-central-1.compute.internal   m5.large        br_default-20220525160725393100000003      True    2022-10-28T03:56:19Z
...
```

The above command prints instance types and node groups. More data is injected by AWS as a node label. You can decide what to pull by picking it from the `kubectl describe node` output:

```
Name:               ip-10-0-116-000.eu-central-1.compute.internal
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/instance-type=m5.large
                    beta.kubernetes.io/os=linux
                    eks.amazonaws.com/capacityType=ON_DEMAND
                    eks.amazonaws.com/nodegroup=br_default-20220525160725393100000003
                    eks.amazonaws.com/nodegroup-image=ami-0246e36000000000
                    eks.amazonaws.com/sourceLaunchTemplateId=lt-0f95aab78b699788c
                    eks.amazonaws.com/sourceLaunchTemplateVersion=1
                    failure-domain.beta.kubernetes.io/region=eu-central-1
                    failure-domain.beta.kubernetes.io/zone=eu-central-1a
                    k8s.io/cloud-provider-aws=be6c0a9c1e11a4070ca9dab664912000
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=ip-10-0-116-000.eu-central-1.compute.internal
                    kubernetes.io/os=linux
                    node.kubernetes.io/instance-type=m5.large
                    topology.kubernetes.io/region=eu-central-1
                    topology.kubernetes.io/zone=eu-central-1a
...
```

In the case of AWS, the node name is not particularly useful. You can change it for the instance id:

```
> k get nodes -o custom-columns=INSTANCE_ID:.spec.providerID,INSTANCE_TYPE:".metadata.labels.node\.kubernetes\.io/instance-type",EKS_NODEGROUP:".metadata.labels.eks\.amazonaws\.co
m/nodegroup",READY:".status.conditions[?(@.reason=='KubeletReady')].status",CREATED_AT:".metadata.creationTimestamp"
Kubeconfig user entry is using deprecated API version client.authentication.k8s.io/v1alpha1. Run 'aws eks update-kubeconfig' to update.
INSTANCE_ID                                  INSTANCE_TYPE   EKS_NODEGROUP                              READY   CREATED_AT
aws:///ap-northeast-1a/i-09603471464edb7d4   m5.2xlarge      br_privileged-20220906113602961400000001   True    2022-11-25T03:33:23Z
aws:///ap-northeast-1a/i-0926e1e0ab36e7d29   m5.large        br_default-20220808183837971200000013      True    2022-11-21T11:15:26Z
aws:///ap-northeast-1a/i-070e1e9afb1c5e5e8   m5.large        br_default-20220808183837971200000013      True    2022-10-28T03:52:51Z
aws:///ap-northeast-1a/i-0d2a323d4fa70b08d   m5.large        br_default-20220808183837971200000013      True    2022-10-27T12:46:56Z
aws:///ap-northeast-1a/i-0e8404aea87c57624   m5.2xlarge      br_privileged-20220906113602961400000001   True    2022-11-25T10:55:28Z
aws:///ap-northeast-1a/i-04a0f5e5edfd58374   m5.2xlarge      br_privileged-20220906113602961400000001   True    2022-11-25T10:16:36Z
...
```
