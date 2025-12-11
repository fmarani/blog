+++
date = "2012-05-06 11:39:37+00:00"
title = "Ubuntu on EC2, the simple way."
tags = ["amazon ec2", "web architectures"]
description = "Running compute-heavy workloads on Amazon's virtual machines"
+++

Problem
---

Sometime ago I had to run a statistical software on some data, the computation was really expensive, it was impractical to run it on my small laptop as it would hung for hours waiting for a result to come up. I thought about running it on Amazon.

Solution
---

Amazon EC2 is a virtual machine hosting service, also known as IaaS. Quite similar to Linode or Rackspace. Payment here is per hour, differently from Linode... slightly on the expensive side i might add, but top-end VMs are quite powerful.

First step is to go through the setup procedure in order to have ec2 tools setup on your machine. I run ubuntu on my laptop and i applied the steps described <a href="https://help.ubuntu.com/community/EC2StartersGuide" target="_blank">here</a>.

After having installed the api tools and having put all EC2 environment variables in your .bashrc file, type:

```
ec2-describe-images -o amazon
```

You should see the list of public AMIs from amazon. If you don't there are problems with your configuration.

By default the firewall blocks every access to every port, you have to explicitly enable access in the security group that is associated to your machine (or in the default security group).

<code>ec2-authorize default -p 22</code>

This enables the ssh port. Next thing is to create the machine, i used ubuntu 11.10 64bit EBS-backed. It's ami code is ami-895069fd. It is possible to bootstrap this specific image with a bootstrap script:

<code>ec2-run-instances ami-895069fd -t m1.large --user-data-file ~/ec2/bootstrap.sh</code>

This is an example bootstrap file:

```shell
#!/bin/bash

set -e -x
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get upgrade -y

apt-get install -y xorg
apt-get install -y fluxbox
apt-get install -y vnc4server

wget --user="YOURUSER" --password="YOURPASS" -O /tmp/vnc-conf.tgz https://server/vnc-bootstrap.tgz
cd /home/ubuntu && tar xfvz /tmp/vnc-conf.tgz && chmod -R 700 .vnc

chmod 755 /etc/X11/xinit/xinitrc
su -c vnc4server ubuntu
```

In this script, i install all the packages i need and i download some initial data. For anything more serious than this i advise you to look into Puppet or Chef.