---
title: "EventBridge can be used to decouple specific SQS queues from producers"
date: "2023-11-01T14:24:04+01:00"
tags: []
---

SQS queues have producers (sometimes referred as publishers) and consumers. Both entities need to know the queue ARN (the Amazon ID system) to connect to. Sometimes it is desirable to not share the queue ARN directly with producers, and instead give them access to something else.

An EventBridge bus can be used as a reference to give producers a place to send messages to. Eventbridge will then forward its input to the SQS queue (or set of queues) that have been set as targets. In this way, the consuming system would be able to change the queue names and parameters more freely, without having to coordinate with the producing system, which might be owned by a different team or different company.

With direct coupling: `Producer -> SQS queue -> Consumer`

With Eventbridge decoupling: `Producer -> Eventbridge bus -> SQS queue -> Consumer`

The simplest setup is a dedicated bus, which can be accessed from the external party. You can use their AWS principal to grant cross-account access. This is an example policy:

```
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "ExternalCompanyAccess",
    "Effect": "Allow",
    "Principal": {
      "AWS": "arn:aws:iam::11111110000:root"
    },
    "Action": "events:PutEvents",
    "Resource": "arn:aws:events:eu-east-1:2220002200022:event-bus/bus-name"
  }]
}
```

This new dedicated bus need to have at least one match-all rule. This is the match-all event pattern:

```
{
  "source": [{
    "prefix": ""
  }]
}
```

Final step is to create a SQS target, which is straight-forward. You can add any number of SQS targets, and there are also many other type of targets if you eventually decide to stop using SQS altogether.
