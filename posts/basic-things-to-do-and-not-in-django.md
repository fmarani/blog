+++
date = "2012-09-23 19:33:30+00:00"
title = "Basic things to do and not in Django"
tags = ["django"]
description = "Common mistakes and best practices for Django projects"
+++

Make software dependent on absolute paths: One of the projects i was working on had all module imports including the project main folder name. That in turn made impossible to have the same project installed 2 times in the same folder with 2 distinct names. (e.g. 2 versions of the staging site). Sometime is even worse than this, when you have a full path in the code. These should always be in configuration files which are changeable at deployment.

Massive views.py file: It is probably time to split the project in separate applications. Also try to remove the code which is not directly view related and separate it in different files. Django has a very good form validation framework, if you use it your views.py file will shrink considerably.

Please no grammatical mistakes: This is very bad and means you did not care about the project enough, plus not everyone is using IDEs so you should make the effort to write function names properly.

Don't throw everything in the database: I hate when applications are dependent on huge models, models should be lean and you should be able to recreate them easily enough with fixtures. For the sake of forensics, you really should make good use of logging and perhaps keep a backup of the imported feeds. Not all data needs to be in the database, only the one your project uses.

Make all a varchar: Relational databases are strongly typed and this is the reason why they can do all the things they do... if you want more flexibility, use mongodb.

Always have automated deployments: Even if all you do is rsync to a server, you should have that command in a bash or fabric script.

Not reinvent Django features: Unless there is no way to solve your problem with existing tools... usually Django modules are pretty extensible and rock-solid.

Use django-extensions and Django debug toolbar: It's like going camping and not having the swiss army knife. My favourite parts are the graph models extensions which makes you an image representing all models and connections between them, and the runserver_plus which uses the Werkzeug debugger to run your code... very handy the debugger. Regarding the debug toolbar, makes it really easy to diagnose what's gone wrong when rendering a page: are all variables included in the template, some bad value coming back from the db, etc...

Include everything needed for the project in the repository: No files laying around the server should exist unless they are checked in the repo, this includes apache conf files... unless you have a separate repository for them.

Always use virtualenv: Really, projects without virtualenv are a thing of the past, and using it is trivial. Another thing to do is always have a requirements.txt in the repository, so you can recreate the virtualenv easily.

Keep the project clean: Which means remove old features when they are not required anymore, just like you would clean your room from time to time. Keep in mind that all code on the site need to be maintained, and if it's not worth maintaining it anymore, it's time to get rid of it.

Always use RequestContext and STATIC_URL for rendering templates: In that case you do not hard-code links to your static media. It's one of those things easy to do and will make your life easier when you will have a separate static server or serve files through a CDN.

 