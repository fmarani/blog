+++
date = "2010-10-03 16:09:47+00:00"
title = "Nginx rocks"
tags = ["nginx", "web architectures"]
description = "Serving gigabytes of images with zero restarts for months"
+++

I have installed Nginx some time ago on one of our busiest servers on our partner's networks, i promised i would have blogged about this and now it's about time. This server only serves images of products sold thorugh our e-commerce site. The first configuration was only a simple web server which was serving already resized images directly, due to the massive amount of images and the cleaning of it which was taking days, i decided to use Nginx in reverse proxy mode. I have to say i am still impressed, after 6-7 months, about this software. I've never had to restart it one time except for little configuration tweaks.

This software is so good that we decided to put images that compose emails on this server as well. This is kind of critical because, after the nightly mail-out, there are 5-6 hours in the morning with constants spikes of traffic. Again, absolutely no side-effects, Nginx relentlessly serves gigabytes and gigabytes of images as if nothing happened.

This is our configuration:

```nginx
# FIRST TIER TO ANSWER HTTP REQUESTS FOR IMAGES
# SECOND TIER IS APACHE

user  apache;
worker_processes  4; // same as number of cpu cores

error_log  logs/error.log;
pid        logs/nginx.pid;

events {
worker_connections  512;
}

http {
include       mime.types;
default_type  application/octet-stream;

log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
'$status $body_bytes_sent "$http_referer" '
'"$http_user_agent" "$http_x_forwarded_for"';

# access_log  logs/access.log  main;
access_log off;

sendfile        on;
keepalive_timeout  65;

upstream imageserver {
server 127.0.0.1:81 fail_timeout=120s;
}

proxy_cache_path /opt/nginx/cache levels=2:2:2 keys_zone=imagecache:10m;
proxy_temp_path /opt/nginx/cache_temp;

server {
listen       80;
server_name  NAME.DOMAIN.COM;
#access_log  logs/host.access.log  main; //disabled for speed

root /home/website/root;
index index.php index.html index.htm;

gzip on;
gzip_disable "msie6";
gzip_disable "Lynx";
gzip_comp_level 8;
gzip_min_length 1000;
gzip_proxied any;
gzip_types text/plain text/css application/x-javascript text/xml application/xml application/xml+rss text/javascript;

location /nginx_status {
stub_status on;
access_log   off;
allow 127.0.0.1;
deny all;
}

location /images {
expires 15d;

client_max_body_size 8m;

proxy_redirect off;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_pass_header Set-Cookie;

proxy_cache imagecache;
proxy_cache_valid 200 302 60m;
proxy_cache_valid 404 5m;

proxy_cache_use_stale timeout;
proxy_connect_timeout 40;
proxy_read_timeout 80;

# REGEX to filter out bad image urls
if ($uri ~* ".*/([a-z]+)/[a-z0-9\-]+/([a-z0-9\-]+)/([0-9]+)/([0-9]+)/([a-z0-9\-]*)/([a-z0-9\-]+)\.jpg$") {     #case insensitive
proxy_pass http://imageserver;
}

}

error_page   500 502 503 504  /50x.html;
location = /50x.html {
root   html;
}

location ~ /\.ht {
deny  all;
}
}
}
```

This configuration is able to serve a constant flux of 1.5Mb/s, which i reckon is about 200 requests/sec for an average file of 3Kb. Most of the requests are served directly by Nginx, some others go through to Apache which has in average 200 connnections opened.

The version of nginx used is 0.7.65 compiled from sources. This because new 0.7 has an improved reverse caching module which was needed for this.

EDIT: I've been doing some statistics on a recent normal day: 100Gb of traffic and 25-30 million images transferred. Server load was below the limit and most of it coming from Apache. Not bad at all!
