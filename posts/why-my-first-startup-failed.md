+++
date = "2014-01-26 15:24:59+00:00"
title = "Why my first startup failed - tabs.to"
tags = ["startup", "tabs.to"]
description = "Learning the hard way about overengineering and burning out"
+++


![logo](/attachments/logo.png "Tabs.to")

Tabs.to was a url shortener, but with a twist, it could support multiple urls and it was displaying them with a sort of tabbed interface which you could use to switch between pages. The use case I was seeing was sending multiple links via twitter, and by doing so you would have saved space. In hindsight, it seems pretty short-sighted but that was the problem I had. This was in 2010, 4 years ago.

I really liked the idea, it was simple, easy to explain, easy to pitch. The way I saw this challenge was really a growth problem, more than a revenue problem. After having grown big, we would have had a ton of data about sites, and we could have built a kickass analytics tool on it. 

I am pretty sure the reason why this failed was mainly overengineering, will come back to this later.

I wanted the site to be accessible through Web and API. I wanted to build this in Scala and MongoDB, two technologies I did not know, for the web-serving part, and Python/RabbitMQ for the offline processing part. I wanted the site to scale to thousands of requests, and it did. It took 6 months of hard work, every day, every weekend, it took an incredible amount of energy. A good friend of mine made me a logo and a design, someone on elance made me the front-end, my other co-founder helped me define the product, do wireframes and prioritize what needed to be done.

I started talking about this to people, and I also went to Hacker News in London to present this. It was a 20 minute presentation to a lot of people, it was fairly technical because I believed that the idea did not require explanation and technology was what I am passionate about. At the end I have received some good feedback, and I also had some angel investors interested in the product. People offered to mentor me, and I had interesting chats with some of them in the following weeks. We also met a lawyer for possibly patenting parts of this idea.

People started to use the product, but numbers were low and fundamental problems started to appear in the product. It turns out many websites did not like to be loaded in an frame, either by giving back a white page or escaping the frame. Resolving this was going to be really tricky, to give to the user the same site, I would have had to create a browser extension and use the real browser tabs for that.

Besides that, because I focused so much on technology and scaling, the energy I invested here was too high and I did not enough of what really matters in a startup, like market research, talking to other companies for integrations, offer content online myself, talking to early adopters.

People have a limited amount of energy before they burn out. At some point I exhausted mine, all the energy I spent on making the perfect platform turned out to have been misplaced.

I learned in the hard way from this experience, but it was really good learning. You can be really motivated at something, but motivation is not infinite, needs to be reinforced with success.