+++
date = "2015-11-15 12:00:00+00:00"
title = "Assessing quality by functionality mapping"
tags = ["product", " software"]
description = "Measuring how technology supports your product's user journeys"
+++

This post is about measuring how the technology supports your current product, that being a single marketable entity. If we accept that the definition of quality is having as less bugs as possible, and the more code you write the more bugs you insert, you will have to accept the fact that the more code you write the less quality you will be able to get out of it. A good software project has the right amount of code to support the features that your product strategy dictates. That I think is independent of the paradigm you adopt, monolith or microservice, functional or not, etc. This post is really about the product.

A web product is made of pages and hyperlinks that bring you to other pages, all this resulting in user journeys. Your product strategy tells you what are the journeys your product needs, ux and marketing are more concerned about the how these steps are presented. Technology is influenced by both the what and the how, so we need to map both. These are some ideas on how to map out softwares based on various system architectures.

Simple case (Django/RoR-type setup):

- user journey description
- where the html is 
- where the backend code files are 
- does the backend have unit tests 
- what db tables it is using 
- any SaaS dependency

Single page apps:

- user journey description
- where the html/js component is 
- what api is using 
- does the js component have unit tests 
- does the js depend on other SaaS api 
- where is the backend code to support those api 
- does the backend component have unit tests 
- what db tables it is using 
- any dependency on other installed software 
- any SaaS dependency

Single page apps with microservices:

- user journey description
- where the html/js component is 
- what api is using 
- does the js component have unit tests 
- does the js depend on other SaaS api 
- where is the backend code to support those api 
- does the backend component have unit tests 
- what other microservices is the backend talking to 
- what is the fallback mechanism in case the microservice is unavailable 
- what db tables or nosql resources are these microservices using 
- any dependency on other installed software 
- any SaaS dependency

The more complex your system architecture is, the more layers you will have to map, so the above list is non-exhaustive.

Once you have mapped out every column presented above, you should have a good idea of how good (or entangled) your software architecture is. That is a pretty good base to assess a project's quality. The less things you have in the list the better... you will have less to justify.