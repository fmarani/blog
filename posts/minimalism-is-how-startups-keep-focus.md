+++
date = "2017-03-18T16:30:28Z"
title = "Minimalism is how startups keep the focus"
tags = ["startups", "minimalism"]

+++

I want to blog about this topic because minimalism, meant as the art of doing only the essential, is a very hard thing to do. Writing about things helps me with having a clear mind. I will therefore try to write about it, and rewrite about it in the future as many times as my thinking clears up.

I realize this article will leave you with a ton of space for interpretation. You may have more questions after reading this than answers. This is the goal of this article.

I had the chance to work on some big projects last year, and this year slightly smaller projects, where my job was sitting somewhere between coding and delivery. This was a personal choice. In this space, if there is a "bug", its cost is usually tenfold, because it has a cascading effect. Sometimes it could be the kind of bug that you cannot fix later.

Industry got smarter on this, with safety nets to catch bad practices, but I struggle to support this one-size-fits-all approach that seems to permeate the software industry. Approaches like Best Practices, SCRUM, 3-layer architecture, DRY, JIRA, NoSQL, REST, modularity, reusability, unit-testing, microservices. There are pros and cons for each one of these, and blogged at length by the engineering community. I acknowledge that each one of these acronyms provide common ground for processes and discussions, but why do we have to use them if in our context they do more harm than good?

How do we communicate we want to do something different, because the current industry standard has arguably some problems?

Can we advocate for DRY when we have never seen 5-6 codebases tumbling down the copy-paste route? Can we advocate for unit-tests when every new feature is 90% a rewrite of the old one? Is NoSQL better because it is newer than SQL? Why REST when there is no clear resource to act on? Unfortunately, there is no silver bullet, but we still communicate ground rules by picking an existing approach rather than coming up with one.

I think the only universal solution here is to only do what is needed, but there are no guidelines that help you choose to not do something. Let's try to have a framework to take minimalistic decisions. I can count 5 levels in which minimalism can be applied.


Product minimalism
---

Every feature needs to be mantained. When tackling a roadmap, usually features are added and products created, but this is hardly sustainable in the long term. If you compare building software to building houses, you will understand that you cannot always add rooms without rethinking the house plan.

Product is the medium for business to take place. It needs to be clean and clear. I think the product needs to be minimized so it is very clear what it is. Every time we add something that is not connected with the primary goal of the business, we accumulate product debt. Debt that need to be repaid by either forming a business structure around it, or by removing it from the codebase.

I have been thinking about negative roadmaps lately, which is a list of things you decided not to have anymore, or split out in its separate product with a separate support. I think if everything is measured in usage numbers, it should be pretty clear what is valuable and what is not.


Architecture minimalism
---

How many databases, how many frameworks, languages and libraries do you need to build your product? Does each one of these choices justify the time invested in learning and maintaining it? Do they enable you to do something that you would not be able to do otherwise?

I am not against using the right tool for the job. I think sometimes it is better to have a flexible tool for the job instead of many right tools. This type of choice buys you options and gives you only one thing to care about.

How about a tool that fits you 90%? Does another tool that covers the remaining 10% justifies the added business value?

As a last thing, this is connected to product minimalism. Any product reduction or modification should reflect on here. If a product feature is removed, but you still keep the underlying software architecture for it, you have architecture debt.

I do not think architecture design by committee works, ever, especially in startups. At the same time, one person designing this and telling the team the outcome does not work either.

Please value your team opinions, but ultimately good points need to be discerned from bad ones, and the last ones discarded. Listening does not mean doing everything everybody wants.


Infrastructure minimalism
---

The amount of effort you need to put in managing a network of servers is often undervalued. DevOps can drain a lot of your time if you are not careful.

I found that the average developer is quite bad at infrastructure, perhaps because they are different disciplines. This could be part of the reason why microservices are becoming such a buzzword nowadays.

Plenty has been written about microservices and how you should practice a monolith first approach when the business is young and the product is still in its definition phase. I agree with the general idea.

From a infrastructure management perspective, microservices is the worst option: you have to manage a distributed system with multiple points of failure which needs careful coordination when releasing, especially paying attention to forward and backward compatibility of their REST interfaces (or any other i/o format). Essentially a full-time job.

A much better use of your time is to lay down the infrastructure in a way that is easy to automate. You should aim to have a script for everything. Creating servers, installing databases, deploy and releasing code, etc. If you know you may have to do what you did a second time, automate it. If you are not sure, at least document it.


Code minimalism
---

I feel like here there is potentially the biggest impact for this. Only create software layers and apply clever design patterns if they provide better common groud for the team, which can then use those to apply higher level thinking. In the other words, the abstraction needs to be good and solid. If an abstraction leaks, it is time to remove it, for the same reason you would remove a leaky pipe from your kitchen.

Recently I read some advice that was saying that you should write code in a way that is easy to remove. I think it is a good starting point to think about this.

I think in the engineering profession there is a lot of intellectual pride in being picked to build the backbone of a new codebase, but sometimes comes with intellectual arrogance attached. Building software is expected to be a very fluid process, and it can probably be that way if we try to limit the number of hard choices we feel the urge to make.


Process minimalism
---

For me, there is nothing worse than having too many processes, but I also understand that for some type of people having a process for communicating gives you more comfort.

First off, processes are about communication, therefore they can be of two kinds: asynchronous and synchronous. Synchronous comunications are more costly in terms of stress and interruption of flow, but sometimes lead to solutions more quickly.

If your focus is progressing with work, the worst option is having a synchonous communication session that does not lead to any helpful outcome to anyone. If your focus is having fun, take 2 hours off at the end of the day and go to the pub. Nobody can claim to do constant progress 8 hours a day.

To me, the minimum set of meetings an engineering team should have are the ones, with explicit no blame policy, that are dedicated to voicing concerns (or support) towards specific team processes, architecture, infrastructure or code. Better if these areas are taken one at a time. What in SCRUM terms is called retrospective is one of these.


Conclusions
---

If our goal is to do the things that work and do not do the things that do not work, we have to be open minded and question everything.

The product you do not put together will not confuse your user, the architecture you do not insert in your repository will not give any more headaches to engineers, the infrastructure you do not provision on your servers will not break, the process you do not have in place will avoid people telling you they have too many meetings. The code you do not write never crashes.

Let's agree that sometimes not doing, or undoing, something is a better course of action.
