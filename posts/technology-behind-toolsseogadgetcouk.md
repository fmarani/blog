+++
date = "2012-11-25 17:30:21+00:00"
title = "Technology behind tools.seogadget.co.uk"
tags = ["celery", "django", "scalability"]
description = "Building a scalable link analysis tool with Django and Celery"
+++

Scalability was one of the primary concerns when we started building the tool. Essentially, the tool gathers numbers about links you post, it is quite straightforward. To gather these numbers, our tool uses many external APIs and in a way acts as a sort of proxy between the user and many other 3rd party API providers, on top of which some internal indicators are derived. Many tools allow you to do that, but, regarding scalability, some ways are better than others. Much better actually. Gathering information for 1000 urls a day is different than doing it on 1 million, lots of challenges came in the way.
<h2>TECHNOLOGY</h2>
Deciding on which platform to use, we ended up using the well-known combo Python-Django-Celery. It is the one i have most experience with, and the task is really I/O bound therefore it is not one of those cases in which writing everything in C makes a big difference. This combo also allows us to code things pretty quickly, testing various methods and combinations. The real complexity is in the Celery backend, which is where the data gathering takes place.
<h2>WORKFLOW</h2>
Requests could come in through API or through the Web interface. Web interface is a better example because that is the only way now to send multiple urls at once. When URLs enter into the system, each one of those is done in parallel. For every url, there are two rounds of data gathering, the first gets part of the final results, and then a second round gets the results that are dependent on the first round of numbers.

All these single rounds of API calls are done asynchronously, not sequentially. We make heavy use of Celery advanced features such as tasksets and chords to make sure we squeeze every bit of performance we can from the system.

Each background task takes then care of storing these numbers in a PostgreSql database server, which they later get pulled back in the Web interface (or API results)
<h2>INFRASTRUCTURE</h2>
Heroku has allowed us to build something quickly, although we had to switch to an hybrid EC2 - Heroku, mainly because of heavy use of RabbitMQ. The advantage of Heroku is that you can scale the number of instances pretty quickly if there is a lot of traffic. We distribute the background tasks using RabbitMQ which has gone through some configuration changes. Some of the more interesting tweaks have gone into the configuration of Celery, especially on setting expiration limits for every single external API call to 3rd party systems. We do not want 3rd party APIs failure to bring down our service. All this has been wrapped up in a quite minimal interface, using Twitter Bootstrap as a CSS framework. Very easy to use.
<h2>IDEAS FOR THE FUTURE</h2>
There has been some thought about improving the "spam" flag with something which can learn and adapt to new types of spam. What features to take into account when deciding about spammy links is also under review. There is also a lot of enhancements we can do on the APIs, such as different tiers, perhaps a tier with a different priority (e.g. reduced response time) or different limits which will be a paid option. There is also always room for speed improvements such as bulk queries, result caching, etc... what is the feature you would like to see in this tool?