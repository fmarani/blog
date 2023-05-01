---
title: "Routing in AWS checks that source IP or destination IP is respected"
date: "2023-05-01T13:12:18+02:00"
tags: ["aws", "network"]
---

A EC2 instance that you launch is only allowed to receive traffic if the destination IP matches what the DHCP server assigned. Similarly, a EC2 instance is allowed to use a certain IP as source only if it was DHCP assigned. This is a safety measure built in the AWS VPC layer.

This is desirable in most cases, except when you are deploying a NAT instance, or a VPN. In which case, at creation time, you need to disable this check.

In Terraform you can do this either at the EC2 instance level, or at the ENI level.

```hcl
resource "aws_network_interface" "this" {
  source_dest_check = false
  ...
}

resource "aws_instance" "this" {
  instance_type        = ...
  ami                  = var.exchange_gateway_server_ami

  ...
}

resource "aws_network_interface_attachment" "public" {
  instance_id          = aws_instance.this.id
  network_interface_id = aws_network_interface.this.id
  device_index         = 1
}
```
