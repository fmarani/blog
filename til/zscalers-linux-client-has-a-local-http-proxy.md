---
title: "Zscaler's Linux client has a local HTTP proxy"
date: "2026-10-09T10:44:19+02:00"
tags: ["zscaler", "networking", "linux"]
---

At work we reach internal applications through Zscaler Private Access. On Linux the Client Connector captures traffic with a TUN device and has no option to work as a SOCKS or HTTP proxy. While looking at how the client is put together, I found one anyway.

There are three processes. `zsaservice` is a root watchdog and `zstunnel` is the root data plane. `ZSTray` is the Qt UI, which runs as the user and handles the SAML login. Listing the sockets showed `zstunnel` listening on port 9000, on `127.0.0.1` and on the tunnel addresses `100.64.0.1` and `[fc00::6440:1]`. It answers HTTP CONNECT:

```
$ printf 'CONNECT example.com:443 HTTP/1.1\r\nHost: example.com:443\r\n\r\n' | nc 127.0.0.1 9000
HTTP/1.1 200 Connection Established
Proxy-Agent: Ztunnel/1.0
```

It also routes ZPA app segments. A request to an internal hostname through the proxy returned the same page as the direct path through the TUN. That is still true when the local DNS answer is wrong, because the proxy resolves the name itself:

```
$ curl -x http://127.0.0.1:9000 \
    --resolve app.internal.example:443:192.0.2.1 \
    https://app.internal.example/
```

That still returns 200.

It is interesting, but it does not give you a choice of what goes through Zscaler. Using the proxy sends traffic through Zscaler, but not using it does not keep traffic out, because the TUN captures everything else anyway. To keep traffic out you would have to disable the TUN, and probably the whole client, and then there is nothing left to choose between. It is also undocumented, so an upgrade can change it.
