+++
date = "2015-01-14 11:45:46+00:00"
title = "Working with caches and Memcache"
tags = ["web architectures", "cache"]
description = "When and how to use caching without introducing bugs"
+++

The traditional use of Memcache is to cache things like computations that take some time or result coming from external system with limited throughput. Examples of these may be database queries (sometimes long to compute), search queries coming from dedicated search services or simply feeds from other sites that don't change often.

Memcache is both a cache system and a separate component in your system architecture, so it is very important to understand the implications. There are many negatives: it is another dependency, which adds complexity to the system, it potentially contains stale data, and it is a potential point of failure. Please consider all these things before inserting a cache in your app, many annoying and hard to find bugs in software development are related to cache.

On the positive side, if done right, caching means increase in performance for the website and less stress for the underlying service. Start by looking at the areas of your application which are executed very frequently and are computationally or IO heavy. For example, loading recursive structures (like category trees) from relational databases (which are flat) is an expensive operation.

One common usecase is search: results depend only on a set of parameters which are repetitive. If parameters are not repetitive, they can be made to by approximating them to some common form: free text keywords can be stemmed (see NLP), geographic coordinates can be rounded, number of results can be made multiple of some base number, etc... in this way we increase the cache hit rate without losing too much precision.

This exercise of increasing cache hits is quite common, and it is also very common in compilers when they try to align structures in a way that they fit CPU caches. The principle is similar, you want to increase the likelihood of having fast read operations instead of slow operations.

In python there are libraries to interact with memcache, as in Django. They are quite small as the protocol is very simple to understand.

I am generally against systems that automatically cache all database queries: if you have a good schema, you should not need it. We used to cache all Postgresql queries but the speed gain was not noticeable so we removed it, we have a fast network, enough memory for the disk buffer and, honestly, not a great volume of complex queries.

The setup of Memcache is really simple, you can start by just using the defaults after the installation. The default cache size is 64Mb and when exceeding that it will start to delete keys in least recently used order. 