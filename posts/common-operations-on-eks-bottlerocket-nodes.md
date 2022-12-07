+++
title = "Common operations on Bottlerocket"
tags = ["kubernetes", "eks"]
date = "2022-12-07T22:19:15Z"
+++

At work we are in the midst of a complex migration to EKS, and one of the choices that we had to make was what flavour of nodes we wanted to run our containers on. We needed something that did not impose too many technical restrictions but, at the same time, not burden us with a high maintenance cost.

EKS can be hosted on [many types](https://docs.aws.amazon.com/eks/latest/userguide/eks-compute.html) of nodes. EKS managed node groups seem to strike the right balance between flexibility and ease of use for us. Fargate was ruled out because it cannot run daemonsets, a K8s feature that we were planning to use.

Having picked the node type, we had to choose the OS. Bottlerocket is the newer alternative to Amazon Linux for this purpose, and it was appealing to us given how lean it is. Its security stance makes it a very inconvenient target for hackers.

Nodes in K8s are something you rarely operate on. We have been doing this just a bunch of times, mostly for:

- troubleshooting network issues
- checking kubelet logs

Additionally, Bottlerocket nodes likely need some additional infrastructure work.

- Setting automatic security updates
- Changing storage/network parameters

# Network troubleshooting

Each EC2 Bottlerocket instance runs a control container. The only way to get a shell on a node is to use AWS SSM to jump onto the control container, and from there you can run some basic commands. You can use this to run pings, but you cannot run anything as root.

Entering the admin container is the only way to get a root shell on a node, and this option need to be explicitly enabled through the EC2 userdata configuration, configured at the AWS launch template level. Once you have root access, things get easier:

```
$ enter-admin-container
...
# yum install nmap-ncat
...
Complete!

# nc -v -w 5 -z google.com 80
...
```

# Checking kubelet logs

Again, admin container is needed. You can get access to the logs by using `journalctl`:

```
# journalctl -u kubelet.service 
Dec 02 15:04:46 ip-1-2-3-4.eu-central-1.compute.internal systemd[1]: Starting Kubelet...
Dec 02 15:04:47 ip-1-2-3-4.eu-central-1.compute.internal host-ctr[3339]: time="2022-12-02T15:04:47Z" level=info msg="pulling with Amazon ECR Resolver" ref="ecr.aws/arn:aws:ecr:eu-central-1:placeholder:repository/eks/pause:3.1-eksbuild.1"
Dec 02 15:04:48 ip-1-2-3-4.eu-central-1.compute.internal host-ctr[3339]: time="2022-12-02T15:04:48Z" level=info msg="pulled image successfully" img="ecr.aws/arn:aws:ecr:eu-central-1:placeholder:repository/eks/pause:3.1-eksbuild.1"
Dec 02 15:04:48 ip-1-2-3-4.eu-central-1.compute.internal host-ctr[3339]: time="2022-12-02T15:04:48Z" level=info msg="unpacking image..." img="ecr.aws/arn:aws:ecr:eu-central-1:placeholder:repository/eks/pause:3.1-eksbuild.1"
Dec 02 15:04:48 ip-1-2-3-4.eu-central-1.compute.internal host-ctr[3339]: time="2022-12-02T15:04:48Z" level=info msg="tagging image" img="placeholder.dkr.ecr.eu-central-1.amazonaws.com/eks/pause:3.1-eksbuild.1"
...
```

If the kubelet is not able to connect to the API server, or not setting the SSL connections properly, you would see the errors here.


# Automatic security updates

Our clusters are deployed via Terraform, including its node groups. The node groups are setup with a launch template which, at every TF run, will query for the latest Bottlerocket OS version and then apply it to the node group configuration.

Querying the AMI catalogue is done through a data source:

```terraform
data "aws_ami" "bottlerocket_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["bottlerocket-aws-k8s-${var.k8s_version}-${var.architecture}-*"]
  }
}
```

Connecting this to a launch template, which is then connected to a node group definition, causes a rolling node update of the OS at every AMI change. This process works well for us, due to our heavy TF usage.


# Changing storage/network parameters

Bottlerocket instances come with 2 disks. The first one is reserved for the filesystem and the second is available for containers to use. Internally, each pod gets the entirety of the second disk mounted as a container overlay filesystem, but 20 GB was not enough for us. It is also not encrypted by default, something that we had to change.

```
resource "aws_launch_template" "workers" {
  ...

  block_device_mappings {
    device_name = "/dev/xvdb"

    ebs {
      volume_size           = "100"
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }
  ...
  network_interfaces {
    security_groups = ...
  }
}
```
