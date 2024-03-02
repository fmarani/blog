+++
title = "Configuring mTLS for HomeAssistant on OPNSense/Nginx"
tags = ["mtls", "opnsense", "nginx"]
description = "A more user-friendly alternative to access all your IoT devices"
date = "2024-03-01T18:19:15Z"
+++

At home I am using HomeAssistant (HASS) for a lot of things. I have it running on a little server on my internal network. So far I have been able to access it externally only through Tailscale but that has a few drawbacks:

- VPN client consumes battery
- Needs to be turned on all the time if you want realtime sensor data
- Not user-friendly enough for family members

I want to be able to access the dashboards and collect data from all mobiles we have, but i do not want to explain the need for a VPN to somebody else, and how to install it. I have decided to use mutual TLS because:

- I can do the initial setup on each mobile
- Our edge router has a public IP, and runs a Nginx reverse proxy
- The HASS mobile app supports TLS client certificates

Creating certificates on OPNSense
---

First step is to create a Certificate authority, which is the entity that will issue certificates. It is the entity that every device need to "trust". If its private key leaks, we cannot guarantee certificates authenticity anymore: do not share that.

![Dedicated CA for external access](/attachments/mtls-opnsense-ca-1.png)

After that, you will need to create a certificate for every client device:

![Configuring certificate for each device](/attachments/mtls-opnsense-ca-2.png)

A server certificate is also needed for HASS, issued by the same CA of client certificates. The only difference is that it requires a Subject Alternative Name specified in order to be acceptable by Android. In this case I used its DNS name, which is static.

![Configuring certificate for HASS](/attachments/mtls-opnsense-ca-3.png)

Configuring Nginx
---

OPNsense has a Nginx plugin that I am normally using to access a few things I am running. To add HASS to it we start by configuring an upstream server entity and an upstream entity.

![Configuring upstream server](/attachments/mtls-opnsense-nginx-1.png)
![Configuring upstream](/attachments/mtls-opnsense-nginx-2.png)

Once that's done, a location entity and a HTTP server entity are needed:

![Configuring location](/attachments/mtls-opnsense-nginx-3.png)
![Configuring HTTP server](/attachments/mtls-opnsense-nginx-4.png)
![Turning on TLS mutual auth](/attachments/mtls-opnsense-nginx-4-1.png)

The mTLS part is configured in the HTTP server section. Make sure that:

- the correct TLS certificate is linked (created in the previous section)
- the client CA is the one used to issue client certificates
- "Verify client certificates" is enabled

Once all the above is done, you can test TLS auth. You should see an error:

![Failed client authentication on Nginx](/attachments/mtls-opnsense-nginx-4-2.png) 

Adding certificates to Android
---

You need to install two certificates: the CA certificate and the client certificate.

Having the CA certificate installed on the phone is the equivalent of telling the system that you trust anything that has been issued using that certificate. The system will stop marking HTTPS connections to HASS as "dangerous". 

This CA certificate can be downloaded from the "Trust / Authorities" section on OPNSense, and its a file with a CRT extension. Once that is on the phone, you have to install it via "Settings / Install a certificate / CA certificate"

![Installing a CA](/attachments/mtls-opnsense-android-ca-2.png)

The client certificate is available in the "Trust / Certificates" section. Pick an export password and export the certificate in p12 format (also known as PKCS #12). Once it's on the mobile, decrypt it and install it as "VPN and app user certificate".

![Installing a PKC12](/attachments/mtls-opnsense-android-cert-2.png)

You should be able to use it now in apps that support TLS client certificate selection (another example is Chrome).

![Selecting a client cert](/attachments/mtls-opnsense-android-cert-3.png)
