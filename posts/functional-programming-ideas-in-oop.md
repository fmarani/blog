+++
date = "2011-03-27 13:29:33+00:00"
title = "Functional Programming ideas in OOP"
tags = ["development", "functional programming", "scala"]
description = "How functional thinking changed my object-oriented programming style"
+++

About a year and half ago I started to be interested in Scala. Scala is a hybrid between an Object Oriented language and a Functional Language, and while i was using it i learnt to appreciate more and more the Functional part. I will not hide that the most difficult part in learning Scala was because of that.

The mindset when solving problems using FP is different because it forces you to think in terms of mapping transformations rather than step-by-step algorithms. Type systems are also very strong, more than the OOP i know.

Without getting the rant go too far, I found that my OOP style is now really influenced by the functional thinking:

- lots of small functions, generally short, with strict behaviour.
- functional style is usually more testable because by definition there is no side effect in the code. The code does only one thing and function application to a state A always returns state B. This links to <a href="http://en.wikipedia.org/wiki/Referential_transparency_%28computer_science%29">Referential Transparency</a>.
- state is partly responsible for exponential increase of complexity when stacking up code. Inheritance, composition, whatever technique you use. An object variable that changes state inside a nested object is usually quite difficult to follow. I am not going to say all variables need to be read-only, but limiting the scope in which variables are written and overwritten is good.
- if you can choose between stateless and stateful implementations and you are working on the business domain but still do not know it well, go stateless. Stateless implementations are easier to change.
- type systems initially are a pain, but they enforce you to write safe code and ultimately produce better code. Generally i found that there are not many cases in which you want automatic casting to happen. It also clashes with the rule "fail fast", which is really high in my priorities. Type inference at pre-run time is generally what you want, not changing types.
- i found FP use of types leads to more specific code. For instance, I would rather use a "Currency" type than a float type. Being specific is good, less space for doubt. This is not an unquestionable rule, if performance is crucial and compiler does not optimize this code, that is a big mistake..


I am sure there is a lot more about FP, but this is it for now. These are personal opinions, i am not a language theorist. I am interested in practical consequences, and this is what is happening to my way of working.