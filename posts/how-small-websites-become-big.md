+++
date = "2011-03-30 00:42:56+00:00"
title = "How small websites become big"
tags = ["scalability", "web architectures"]
description = "Guidelines for scaling web applications from small to high-traffic"
+++

There is no secret recipe, there is no list of check boxes to tick... just some guidelines. Part of these lessons have been learned in the hard way, part because i have been always taught that if you want to be the best, you have to copy the best. There is plenty of literature on Internet about this... read, understand and copy.

I think the art of building high-traffic websites is part about the code, but mostly about your web architecture and the tools you use. Here some points, from basic to advanced.
<ul>
	<li>Separation between web server and database server is a basic step. Do it if not for speed, for safety. If the database server gets overloaded, your web server will still be up and running. If one of the two breaks, you need half the time to go back online. If the website goes much slower, you over-rely on the database. You may have to rethink how you use databases.</li>
	<li>Databases often are the main bottleneck of your website. Everything that is I/O related is a bottleneck because no matter what server you have, disks will always be a order of magnitude slower than memory. Consider running these servers on physical machines rather than virtual servers, with properly fast hardware.</li>
	<li>Optimize your queries, use indexes on fields that you search on frequently. This can make a big difference. Databases are weird creatures, you need to know them well before feeling safe.</li>
	<li>Caches are both a blessing and a curse. Using systems like Memcache (or Redis) really makes a difference. Install memcache on every webserver machine and cache all the SELECTs that can be re-used in the next X minutes. When the cache is empty, execute the query on the database and put the results in the cache for later retrieval.</li>
	<li>Optimization makes much sense in certain areas of code. Use profiling tools to see which functions/classes get executed more often and modify that code to make it fast.</li>
	<li>Do not blindly believe ORM is always a good solution. In fact, for heavy db tasks, do not use them.</li>
	<li>Move all your static files on a static web server and serve them from there instead of the main web server. You will split the load without having to do any complex configuration change, other than changing base href in the html. If you have many many files, you may want to tweak the filesystem for it.</li>
	<li>For static files, use a lightweight asynchronous web server like Nginx. Especially if you send emails with lots of images... people tend to open emails as soon as they get to work or during lunch time therefore you will get very high peaks of traffic during those hours. Asynchronous web servers handle traffic spikes much better than traditional web servers.</li>
	<li>Start adding web servers. If you use sessions, you need to store those in a space shared between all web servers, which could be database or shared drive. Shared drive is generally a good idea, put your application on it.. when you upgrade you need to do it only in one location.</li>
	<li>Start thinking about reverse proxy, load balancers and HTTPS accelerators. Here presented in order of cost.. Reverse proxy solve the so-called "spoon feeding" problem quite well, plus you can serve cached responses if configured properly. Nginx is my favourite, followed by Varnish for complex caching policies.</li>
	<li>Database servers are not "full text" search servers. Search is an expensive operation, must be done on dedicated systems, especially if website users do it frequently.</li>
	<li>If you have much off-line data processing to do, do it on a dedicate server. You may want to look into Hadoop if volumes of data are enormous.</li>
	<li>The more code and servers you have, the more likely is that something wrong happens. Learn to log events properly, with all the information you may need. In areas in which performance is really important, you may want to consider conditional logging. It is always better to have some logging than to have extremely fast code which is not debuggable when it fails.</li>
	<li>Automatize! Having a script for everything is important. Deployment is one of the first things to automatize, especially when more than one server is involved.</li>
</ul>
I think i mentioned a lot of things. There are many more to mention but it is more about the management of code and project itself. Maybe in another post.