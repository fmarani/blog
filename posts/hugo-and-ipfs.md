+++
date = "2016-09-14T17:04:43+02:00"
title = "Rebuilding my site with Hugo (and IPFS)"
tags = ["hugo", "static sites", "ipfs"]
description = "Moving from Django to a static site generator with distributed hosting"

+++

## Hugo

This site was built using Django and, given the very simple content model that it had (and almost never changed), I decided to rebuild it in [Hugo](http://gohugo.io). I also was getting fed up of mantaining yet another dynamic site, along with runtime and databases. I picked Hugo because it is written in Go, therefore very easy to get going (one file to install) and it works on any platform.

There are 2 steps for this conversion:

1. Convert the Django template files to Go template files. Converting any simple logic into either Go template logic or JS if needs to be evaluated every time.
2. Cycle over all posts, convert them into files. Write them in a directory (under content) that uses names from the current URLs.

There might be more steps in your setup. In mine, I had to transfer some media files, and define another archetype for normal pages. You can see that at [my repo](https://github.com/fmarani/blog). If you can deal with the Go template language, Hugo is a very nice software.

## Github pages

At this point, the architecture was already much simpler. But I wanted to get rid of the hassle of hosting it. Github pages is free and works pretty well (S3 could also be an option). While I was in the process of following their tutorials, the only slightly obscure step was that I needed two repositories, one for the original Hugo site, and another one for the compiled version. Forget all the tutorials that tell you to create a `gh-pages` branch, those are for project sites, not user sites.

I ended up with:

1. [the original repo](https://github.com/fmarani/blog).
2. [the compiled repo](https://github.com/fmarani/fmarani.github.io). Please note the name of the repo, that's how Github needs it.

The only additional step after all this was to make my domain point to Github, you can find some instructions on their site for that.

## IPFS

Given that all the content is static, it lends itself very well to be distributed rather than just staying on a central server. I installed IPFS on a machine I had available, configured it and let it run as a daemon (quite easy, plenty of docs online). In case Github is down, you can also find this site on IPFS. 

You can either use the [gateway](http://gateway.ipfs.io/ipns/QmfEMiRfCDtPs9B1UsCLWgRWWFp7ZUwZLU2oPWMTqzPKm3/) or use the IPNS directly (QmfEMiRfCDtPs9B1UsCLWgRWWFp7ZUwZLU2oPWMTqzPKm3).

The only caveat I would like to underline here is that you have to use `relativeurls = true` in your Hugo configuration, otherwise absolute URLs will not work well with the IPFS gateway.

## Glue everything together

I created this simple deploy script:

```shell
#!/bin/bash

# Build the project.
hugo

echo -e "\033[0;32mDeploying updates to Github pages...\033[0m"

cd public
git add -A
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"
git push origin master
cd ..

echo -e "\033[0;32mDeploying updates to IPFS...\033[0m"

scp -r public/ USER@HOST:repo
hash=`ssh USER@HOST ipfs add -r -q repo | tail -1`
ssh USER@HOST ipfs name publish $hash
```

Just change the USER@HOST part with your IPFS server. If you run it locally, no need to ssh.
