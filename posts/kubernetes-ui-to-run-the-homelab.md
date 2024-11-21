+++
title = "Kubernetes UI to run the homelab"
tags = ["homelab", "kubernetes", "hex"]
description = "Something I have put together with Django and K3s"
date = "2024-11-21T22:19:15Z"
+++

I have a bunch of servers at home that I bought at different times in the last 10 years: a FreeBSD router, a couple of Lenovo ThinkCentre and a Raspberry PI. Except for the router, I have been running containers on them of various open source software (Nextcloud, Photoprism, HASS, etc).

I have never been happy about how I managed those: what I had was a bunch of shell scripts to run them and to take backups, but there were still manual work, like check their logs, upgrade containers, check that the server itself is healthy, and more.

I decided to install K3s on all of them, and create a minimal Django application to manage the containers I run. I did that because I did not find anything online easy enough to use with Kubernetes underneath.

![Hex dashboard](/attachments/hex-home.png)

For now it is just a couple of ORM models and some Python code to synchronize data with the cluster. Volumes are local-only, therefore containers are bound to a specific server, but it is acceptable for my use case.

![Hex local volumes admin](/attachments/hex-lv-admin.png)

The deployment objects are a bit of a misnomer given that I am hardly using any of the properties of Deployment, besides the most basic ones.

![Hex deployments admin](/attachments/hex-deploy-admin.png)

Right now it only displays some basic data: what pods are running, linking the ports exposed, what nodes are connected along with their statuses and the used space on their local volumes.

If you are interested, let me know. I may send you some updates if I keep working on it:

<form
  action="https://www.formbackend.com/f/f9551acfc3f9952e"
  method="POST"
>
  <label for="name">Name</label>
  <input type="text" id="name" name="name" required>

  <label for="email">Email</label>
  <input type="email" id="email" name="email" required>

  <button type="submit">Submit</button>
</form>

