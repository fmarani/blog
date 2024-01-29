---
title: "How to git-diff SOPS encrypted files"
date: "2024-01-26T16:54:15+01:00"
tags: ["gitops", "sops"]
---

There are a lot of Git commands that displays delta, and all of them support preprocessing files before doing the diffing.

Preprocessors are run based on file extensions. In my case, I want to preprocess files ending with `.yaml.encrypted`.

You create a diff preprocessor in two stages, run from the root of your git repo:

```
> echo "*.yaml.encrypted diff=sopsdiffer" > .gitattributes
> git config diff.sopsdiffer.textconv "sh -c 'sops -d --input-type yaml --output-type yaml \"\$0\" || true - '"
```

The above config will try using SOPS when diffing, failing gracefully if it cannot.

At work we use SOPS with AWS KMS, and we typically use many AWS accounts for the various environments. One way to support this multi account setup is to run git commands in a `aws-vault` subshell:

```
aws-vault exec AWS_PROFILE_WITH_KMS_ACCESS -- git log -p environment-config/ENVIRONMENT_OF_AWS_PROFILE/
```
