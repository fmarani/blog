+++
date = "2011-04-08 01:00:10+00:00"
title = "Logging"
tags = ["python", "logging"]
description = "Best practices for application logging in production systems"
+++

I work on e-commerce platforms, logging is a critical component in this area. Learn how to do it correctly will allow you and everybody else to save time when problems happen. Sometimes it is not just about saving time, but also being able to give correct answers to customers when things go wrong. When interacting with third parties, logging is even more important, because it allows you to understand where the problem lies, in your code or in the external service.

First basic rule is use a logging framework. There are plenty out there, for any language. Modern logging framework are quite complex, they allow you to use different methods of logging (file, database, etc..), log rotation, log levels, email triggering, etc... you should refrain from inventing your own, usually these are pretty extensible anyway. All of the frameworks i have seen have usually the same sort of interface, level based... and they are quite easy to use.

Once you set up your framework, there is a lot to say about how you log things. Do not pretend that people already know your code inside out when they read your application logs. In fact, high are the chances that you do not remember how you coded the functionality if you are looking at logs of old code. Do not give implementation insights in the log files, talk about what the code is doing using the language of the application domain. If you are building a billing application, use billing specific vocabularies. If it is a payment gateway, try to reuse the 3rd party terminology. If you need to, you can quickly lookup the term you used in their documentation and discover what that means. That is something you cannot do if you made that up.

After having chosen how to log things, consider every log call and give it a degree of severity. From an ignorant point of view, you know you should start worrying when you see lots of "Critical" inside the log files, even if you do not know the application domain. If you see one, it is probably a good idea to take a look at the code or at least notify the author.

For critical errors or errors that need to be fixed, useful is to include stats (cpu, memory usage, etc) and location of the code that was being executed. If you had an exception triggered, log the exception stack trace.