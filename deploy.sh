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

scp -r public/ flagz@apps.flagzeta.org:flagzeta_org
hash=`ssh flagz@apps.flagzeta.org ipfs add -r -q flagzeta_org`
ssh flagz@apps.flagzeta.org ipfs name publish $hash

