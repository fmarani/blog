+++
title = "Building a Kubernetes operator - Laying the foundations"
tags = ["operator", "kubernetes"]
description = "Demistifying operators by building a very basic one"
date = "2024-04-11T18:19:15Z"
+++

Operator is a pattern that is commonly used in the Kubernetes ecosystem. It seems that, on average, people considers a piece of code an operator if:
- it defines its own custom resources
- it runs some code in a control loop, continuously reconciling custom resources with a target system.

There are two variations of this pattern that I have also seen used: controllers and jobs. Controllers are like operators, but they do not define custom resources. Instead, they either rely on resources built in the cluster (e.g. Ingress resources) or something much simpler, such as ConfigMaps.

Jobs are even simpler as they do not have a control loop: they are just one-off scripts executed either at their deployment, or on a cron schedule. Relying on volume mounts is also something a Job could do, but I would not consider a good design for a controller/operator.

Let's clarify the Job/Controller/Operator distinction by building a piece of code that targets AWS IAM: our code will reconcile a set of IAM roles/policies for ServiceAccounts with AWS IAM.


The reconciliation code
---

First of all, we need some code that takes policies/roles as input and interacts with AWS APIs. We will use the code below as reference.


```python
import boto3
import json
import os
import yaml

def policy_arn(aws_account_id, name):
    return f"arn:aws:iam::{aws_account_id}:policy/{name}"

def reconcile_policies(client, aws_account_id, policies):
    """
    Reconcile policy documents to policy names

    Format of
    policies = {
       "policyname": "policy........doc"
       "polname2": "policy........doc"
    }
    """
    policies_to_delete = []
    policies_to_update = []
    policies_to_add = list(policies.keys())

    for policy_instance in client.list_policies(Scope="Local")["Policies"]:
        if policy_instance['PolicyName'] not in policies.keys():
            policies_to_delete.append(policy_instance['PolicyName'])
        else:
            policies_to_update.append(policy_instance['PolicyName'])
            policies_to_add.remove(policy_instance['PolicyName'])

    for policy_name in policies_to_delete:
        client.delete_policy(PolicyArn=policy_arn(aws_account_id, policy_name))
    for policy_name in policies_to_update:
        versions = [x["VersionId"] for x in client.list_policy_versions(PolicyArn=policy_arn(aws_account_id, policy_name))["Versions"]]
        oldest_ver = versions[0]
        client.delete_policy_version(PolicyArn=policy_arn(aws_account_id, policy_name), VersionId=oldest_ver)
        client.create_policy_version(PolicyArn=policy_arn(aws_account_id, policy_name), PolicyDocument=json.dumps(policies[policy_name]), SetAsDefault=True)
    for policy_name in policies_to_add:
        client.create_policy(PolicyName=policy_name, PolicyDocument=json.dumps(policies[policy_name]))

def reconcile_roles(client, namespace, serviceaccount_attachments, aws_account_id, oidc_provider_full_id):
    """
    Reconcile policy attachments for the various service accounts

    Format of
    serviceaccount_attachments = {
        "saname": ["policyname", "polname2"]
    }
    """
    def serviceaccount_to_role_map(namespace, service_account):
        return f"eks-sa-{namespace}-{service_account}"

    def create_assume_policy_for_serviceaccount(namespace, service_account):
        return {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Federated": f"arn:aws:iam::{aws_account_id}:oidc-provider/{oidc_provider_full_id}"
                    },
                    "Action": "sts:AssumeRoleWithWebIdentity",
                    "Condition": {
                        "StringEquals": {
                            f"{oidc_provider_full_id}:sub": f"system:serviceaccount:{namespace}:{service_account}",
                            f"{oidc_provider_full_id}:aud": "sts.amazonaws.com"
                        }
                    }
                }
            ]
        }

    roles_available = [x["RoleName"] for x in client.list_roles()["Roles"]]
    for service_account in serviceaccount_attachments.keys():
        role_name = serviceaccount_to_role_map(namespace, service_account)
        if role_name not in roles_available:
            assume_policy = create_assume_policy_for_serviceaccount(namespace, service_account)
            client.create_role(RoleName=role_name, AssumeRolePolicyDocument=json.dumps(assume_policy))

    for service_account, desired_policies_name in serviceaccount_attachments.items():
        role_name = serviceaccount_to_role_map(namespace, service_account)
        desired_policies_name = set(desired_policies_name)
        actual_policies_name = set(x["PolicyName"] for x in client.list_role_policies(RoleName=role_name)["PolicyNames"])
        for policy_to_remove in actual_policies_name - desired_policies_name:
            client.detach_role_policy(RoleName=role_name, PolicyArn=policy_arn(aws_account_id, policy_to_remove))
        for policy_to_add in desired_policies_name - actual_policies_name:
            client.attach_role_policy(RoleName=role_name, PolicyArn=policy_arn(aws_account_id, policy_to_add))

def reconcile_all(client, serviceaccount_attachments, policies):
    namespace = "default"
    aws_account_id = "000000000000"
    oidc_provider_full_id = "oidc.eks.region-code.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"

    reconcile_policies(client, aws_account_id, policies)
    reconcile_roles(client, namespace, serviceaccount_attachments, aws_account_id, oidc_provider_full_id)

if __name__ == "__main__":
    with open("/config/serviceaccount_attachments.yaml", "r") as f:
        serviceaccount_attachments = yaml.safe_load(f.read())
    with open("/config/policies.yaml", "r") as f:
        policies = yaml.safe_load(f.read())

    endpoint_url = os.environ['AWS_ENDPOINT_URL']
    client = boto3.client("iam", endpoint_url=endpoint_url)
    reconcile_all(client, serviceaccount_attachments, policies)
```

In the code above, there are two functions: one to reconcile policies and another for roles. The policy reconciliation function creates/updates/deletes AWS policies based on the policies dictionary passed in. The dictionary's keys are policy names, while the content are the policy JSON documents. 

The role reconciliation function does a similar thing with AWS roles, which is creating/updating roles with a given set of attached policies. The created roles all have a trust policy that federates identities to the OIDC server built into the AWS EKS offering, including a reference to the ServiceAccount name. As long as the service accounts present in k8s have the correct role ARN annotation, the code will grant access to anything the policy allows to: S3, RDS, and so on.

The code works, but does not cover all edge cases.

Run it as a K8s Job
---

If you deploy to K8s via a Gitops repo, the easiest way to run the above is to use a Helm presync hook (via ArgoCD or similar). Imagine the above has been Docker built into a container, here's a bare set of manifests to deploy and run that container:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fff
  annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::0000000:role/eks-sa-default-fff
---
apiVersion: batch/v1
kind: Job
metadata:
  name: iamrun
spec:
  backoffLimit: 4
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: iamrun
        image: iamrun:latest
        env:
        - name: AWS_ENDPOINT_URL
          value: "http://localstack:4566"
        - name: AWS_DEFAULT_REGION
          value: "eu-west-1"
        - name: AWS_ACCESS_KEY_ID
          value: "000000"
        - name: AWS_SECRET_ACCESS_KEY
          value: "000000"
        volumeMounts:
          - name: config-vol
            mountPath: /config
      volumes:
        - name: config-vol
          configMap:
            name: iam-config
            items:
              - key: policies.yaml
                path: policies.yaml
              - key: serviceaccount_attachments.yaml
                path: serviceaccount_attachments.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: iam-config
data:
  policies.yaml: |
    ddd: {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "AllowExampleBucket",
                "Effect": "Allow",
                "Action": [
                    "s3:GetObject",
                    "s3:ListBucket",
                    "s3:GetObjectVersion",
                ],
                "Resource": [
                    "arn:aws:s3:::example-bucket/*",
                    "arn:aws:s3:::example-bucket"
                ]
            }
        ]
    }
  serviceaccount_attachments.yaml: |
    fff:
      - ddd
```

The pod is targeting a copy of [LocalStack](https://docs.localstack.cloud/user-guide/integrations/kubernetes/) deployed in the same namespace as the Job (see `AWS_ENDPOINT_URL`). 

Once the Job has run to completion, any pod in the cluster that is using the `fff` ServiceAccount will be able to access the S3 bucket called `example-bucket`. There is some AWS specific knowledge contained in the code so far, but from here on it is is going to be all generic.

Stop relying on volumeMounts
---

It is best that a controller/operator does not rely on volumeMounts. To get rid of this coupling, we need to change our code to dynamically read its configuration. This is where the complexity on the K8s side increases a bit. The pod need to be able to read any configmap from the cluster that satisfies a criteria. 

A default ServiceAccount does not have such power. A more powerful one is needed, one that allows the pod to introspect the cluster.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: iamcontroller
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: configmap-reader
rules:
- apiGroups: [""]
  resources: ["namespaces", "configmaps"]
  verbs: ["list", "get"] 
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: configmap-reader
subjects:
- kind: ServiceAccount
  name: iamcontroller
  namespace: default
roleRef:
  kind: ClusterRole
  name: configmap-reader
  apiGroup: rbac.authorization.k8s.io
```


Make it a controller
---

Differently from the Job that it was shown in the previous sections, a controller would run the reconciliation routine in an infinite loop. In the loop, it detects content changes in a set of configmaps and triggers the update. This is a simplistic version of that:

```python
import os
import time
import yaml

import kubernetes

from iamrun import reconcile_all  # refers to the reconciliation code

cfg = kubernetes.config
cfg.load_incluster_config()
client = kubernetes.client.CoreV1Api()

def list_iamconfigs():
    namespaces = client.list_namespace()
    for it in namespaces.items:
        try:
            yield it.metadata.name, client.read_namespaced_config_map(namespace=it.metadata.name, name="iam-config").data
        except kubernetes.client.exceptions.ApiException:
            pass

if __name__ == '__main__':
    endpoint_url = os.environ['AWS_ENDPOINT_URL']
    namespace = os.environ.get("NAMESPACE", "default")
    aws_account_id = os.environ.get("AWS_ACCOUNT_ID", "000000000000")
    oidc_provider_full_id = os.environ.get("OIDC_PROVIDER_FULL_ID", "oidc.eks.region-code.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE")

    iamclient = boto3.client("iam", endpoint_url=endpoint_url)

    while True:
        for namespace, cm in list_iamconfigs():
            serviceaccount_attachments = yaml.safe_load(cm['serviceaccount_attachments.yaml'])
            policies = yaml.safe_load(cm['policies.yaml'])
            reconcile_all(iamclient, serviceaccount_attachments, policies, namespace, aws_account_id, oidc_provider_full_id)
        time.sleep(1)
        print("Reconciled at %d" % time.time())
```

Run the controller
---

To run the code above, we need to substitute the Job manifest with a Deployment manifest. The Deployment needs to run with the ServiceAccount we created in the previous section. The rest of the configuration is unchanged: relies on the same configmap we used for the job.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: iamcontroller
  labels:
    app: iamcontroller
spec:
  replicas: 1
  selector:
    matchLabels:
      app: iamcontroller
  template:
    metadata:
      labels:
        app: iamcontroller
    spec:
      serviceAccountName: iamcontroller
      containers:
      - name: iamcontroller
        image: iamrun:latest
        command:
        - python
        - /app/iamcontroller.py
        env:
        - name: AWS_ENDPOINT_URL
          value: "http://localstack:4566"
        - name: AWS_DEFAULT_REGION
          value: "eu-west-1"
        - name: AWS_ACCESS_KEY_ID
          value: "000000"
        - name: AWS_SECRET_ACCESS_KEY
          value: "000000"
```

Conclusions
---

A lot of code and manifests have been shown in this post. The code that we have at the end behaves like an operator, but it is not yet one. The problem is that, in order to use the controller we wrote, all our deployments in our namespaces need to cooperate to define a consistent configmap. 

Another problem is that we have no feedback: a deployment who needs a specific IAM permission would not know if/when that permission has been added. Same thing can be said for K8s administrators: there is no consistent way to report back the status of policy/role reconciliation. Administrators would have to rely on logs, but that is not ideal.

We will continue the journey of transforming the above into an operator in another blog post. Stay tuned.
