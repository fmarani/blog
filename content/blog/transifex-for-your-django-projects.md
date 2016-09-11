+++
date = "2013-01-31 15:39:37+00:00"
title = "Transifex for your Django projects"
tags = ["i18n"]
+++

I am assuming you already created a project on Transifex (in this example is TxProject), either on the hosted version or on the downloadable version, and all the users you need are on there (just one to start is enough). I am also assuming i18n is already setup and you have at least 2 languages already in your project.

The aim of integrating Transifex libraries into your code is to make it really easy to push/pull translations of a project to their web front-end.

<code>pip install transifex-client</code>

First thing is to install their python client, make things much easier instead of manually uploading PO files.

<code>user@host:/workspace/project$ tx init</code>

This creates a .tx folder in your project root to store all tx configuration. You should include this in the repository.

Now suppose you have multiple apps in your django project. For each of those, you should have a locale/ folder inside it with all the application PO files. You need to generate a source language PO file before linking to transifex.

<code>user@host:/workspace/project/apps/main$ ../../manage.py makemessages -l en

user@host:/workspace/project$ tx set --auto-local -r TxProject.main 'apps/main/locale/<lang>/LC_MESSAGES/django.po' --source-lang en --source-file apps/main/locale/en/LC_MESSAGES/django.po -t PO</code>

Repeat the last command for every app you have in your project, changing the resource name (-r option) in TxProject.APPNAME. Next step is to push all your PO files to transifex.

<code>user@host:/workspace/project$ tx push -s -t</code>

After the translations have been done on Transifex, you can pull them into your project by typing.

<code>user@host:/workspace/project$ tx pull</code>

All very nice and easy!