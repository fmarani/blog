+++
date = "2012-01-22 21:49:33+00:00"
title = "Why SOA in a startup sucks"
tags = ["service oriented architecture", "soa", "startup"]
+++

Service Oriented Architectures as i intend are architectures where each component is deployable and usable separately from others. Take as example Amazon, much of their software stack is offered as a service, mainly through an HTTP interface, and marketed as SaaS.

There are tons of reasons why you would want to think to your system as a series of components deployable separately... flexibility, being able to choose the right tools for each component, etc.. i will not talk about the advantages.

Sometime their use is convenient, but there's a lot of hype about it and i want to write what i learned (the hard way) about building your system with this architecture in mind.
<h3>Development cycle is too slow</h3>
When you need to change/add a functionality that changes more than one component, you need to code the functionality in both components and redesign the interaction. If you are using REST it means you will end up modifying URLs and data they return. To sum up, time to add code in component A, time to add code in component B, time to redesign and code changes in the interaction, time to redeploy them... it is quite different from "everything in one component" scenario, the only thing you do is coding.
<h3>Poor testability</h3>
Quite difficult to test functionalities that span multiple services, especially when persistency is involved. How do you limit components side-effects? Perhaps a testing flag passed through an HTTP request can be enough, but that can mean quite a few internal changes which you could skip if everything was integrated.
<h3>Swapping mindsets (and related frustration)</h3>
This is not a technical reason but practical. When juggling between two different software, you have to change mindset and you have to get up to speed again. This mental effort will cost you time that you could have spent otherwise.

 