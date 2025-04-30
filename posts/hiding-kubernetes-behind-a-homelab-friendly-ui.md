+++
title = "Hiding Kubernetes Behind a Homelab-Friendly UI"
tags = ["homelab", "kubernetes", "hex"]
description = "No more Docker, bash scripts and terminals"
date = "2025-04-30T20:19:15Z"
+++

I’ve been tinkering with this for a few months now—migrating the containers I run on my servers to Kubernetes and building a control UI along the way. The goal is to make it possible to perform from the UI everything I’d typically do from the shell. This is the opposite of the platform engineering approach I use at work, where we try to avoid ClickOps as much as possible. Here, I want things to be as UI-driven and simple as they can be.

I have migrated everything now. Things like Frigate and HASS required more capabilities that I originally had in my code, like running containers in privileged mode, using memory volumes and hardware devices. Also, I have added namespace support and a proper REST API. APIs which I used to build a simple applet that integrates with the Gnome desktop.

![Gnome Argos applet](/attachments/hex-argos.png)

Philosophy behind Hex
===

As hinted above, Hex is meant to be simple. The goal is to hide Kubernetes complexity and make it as easy as possible to create/manage running containers. Users should not need to know what a Deployment or a Service is, how to map PVCs or use kubectl. Users should be able to manage their services without seeing K8s YAML or touching a terminal.

The target audience for the tool is people who want to run a homelab, don’t want to deal with K8s directly but still want the high availability of a cluster.

How that translates into implementation
===

Hex uses a different vocabulary, partly abstracting away the K8s terminology: there are 3 basic objects—**Services**, **Volumes**, and **Nodes**.

- A **Service** roughly maps to a Deployment with a single replica and an associated Kubernetes Service. The UI captures basic configuration like image, environment variables, port and volume mappings, and then generates the appropriate backend manifests automatically.
- **Volumes** are persistent paths on the host which can be bound to services. Users can manage them centrally and reattach them across services.
- **Nodes** are the physical machines in the cluster. You can pin services to specific nodes for cases where hardware access is required (e.g., USB devices for Frigate or GPUs).

The UI also strives for short user journeys: user flows are deliberately minimal. Starting a new service is as simple as picking an image, giving it a name, and hitting "Start". You only see the fields that matter—no distractions, no massive forms, no advanced K8s knobs unless you dig for them.

![Add a Service](/attachments/hex-addservice.png)

Even when setting up a more complex container (like Frigate), you’re guided through port mappings, volume selection, and optional device access—all from a single screen.

![Volumes view](/attachments/hex-volumelist.png)

The UI doesn’t try to expose all of Kubernetes—just what matters. It’s not about completeness; it’s about usefulness. You get just the essential operations, nothing more.

If this sounds useful or you’d like to try it out, feel free to reach out. Otherwise, stay tuned—I'll keep posting updates here as things evolve.

