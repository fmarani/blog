+++
date = "2015-01-16 12:51:25+00:00"
title = "Monitoring servers with Munin"
tags = ["monitoring"]
+++

I normally use Munin for server monitoring, it is very easy to install and the kind of tool with not much setup. It may not be the best tool when you have many servers, due to static graph generation. Munin 2, released recently, has a few changes in that regard, they might have improved that.

Munin is mainly a resource usage graph tool, which monitors many metrics from a pool of servers (called nodes). When set up, the monitoring server connects to every node (specified in its configuration) and then asks for a list of current values for all monitored metrics, through a simple text-based protocol. Every node has a list of enabled "plugins" which will be run everytime the server connects to the node. Many plugins come installed by default with Munin, and many additional plugins are available online with an open source license (or public domain). Those plugins have default parameters in it, but much can be customized in the munin-node configuration file.

These "plugins" define the metrics, then the server will render any metrics the node send, without any a priori knowledge. The security model is IP whitelisting: each node has a list of IPs allowed to ask for metrics. The server, by default, will connect to every host every 5 minutes and add all collected metrics to its database. Every hour all the html and graphs are generated and put in a folder where Nginx is able to serve these.

Munin can also be configured to trigger alerts in case a metric changes state between OK, Warning and Critical. Alerts via email are easy to setup and normally enough for basic error reporting. These thresholds can be changed if needed, but the values defined by the plugins are normally good enough. Alerts for specific plugins can be disabled if needed, see [http://serverfault.com/questions/532319/i-have-setup-munin-how-do-i-set-up-alerts-for-specific-parameters](http://serverfault.com/questions/532319/i-have-setup-munin-how-do-i-set-up-alerts-for-specific-parameters "here").

The only daemon in the Munin architecture is munin-node, which runs on every monitored server. On the monitoring server side, everything is managed through cron. Munin is written in Perl and its core modules are quite battle-tested.