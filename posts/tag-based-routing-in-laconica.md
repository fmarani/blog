+++
date = "2009-04-02 23:15:09+00:00"
title = "Tag-based routing in laconi.ca"
tags = ["laconica", "pubsub"]
description = "Using STOMP and JMS selectors to filter microblog content"
+++

Following the last article, i have been experimenting again on laconica and pubsub, this time on the idea of "<a href="http://metajack.im/2009/01/22/filtering-the-real-time-web/" target="_blank">filtering the real time web</a>".

Stomp and generally JMS messages offer the ability to specify headers and body of the message to transmit, in a way that resembles http requests.
In fact, Stomp protocol is really similar to Http protocol, at least in the general structure. The difference is that there are different methods instead of GET, POST, etc..
<blockquote>HTTP:
<code>
POST /item HTTP/1.0
Header: value</code>

POSTBODY</blockquote>
<blockquote>STOMP (after CONNECT command)
<code>
SEND
destination: /item</code>

MESSAGE_BODY</blockquote>
Very readable, like HTTP. However the main difference is that Stomp, like XMPP, is a stateful and bidirectional protocol.

Like XMPP/pubsub, with STOMP and AMQP you can subscribe to a topic (a.k.a. pubsub node). However content-based routing is only done by STOMP and AMQP (in a way specified by the standard).
AMQP is still in its early days. STOMP is a ready-to-use protocol as many of its implementations.

In the Stomp SUBSCRIBE operation it is possible to specify a JMS Selector. It's a header passed when subscribing and it contains a SQL-92 Statement. SQL attributes to match the conditions against are the other headers.

FILTERING LACONICA PUBLIC TIMELINE BY TAGS
---
Before filtering, the code of the previous post used to push notices needs to be enriched a bit. Particularly, tags present in the notices are now put in a separate header.
Doing this allows to be the target of a Selector.

Push an additional header:

```php
//send tags as headers, so they can be used as JMS selectors
common_log(LOG_DEBUG, 'searching for tags ' . $notice->id);
$tags = array();
$tag = new Notice_tag();
$tag->notice_id = $notice->id;
if ($tag->find()) {
while ($tag->fetch()) {
common_log(LOG_DEBUG, 'tag found = ' . $tag->tag);
array_push($tags,$tag->tag);
}
}
$tag->free();

$con->send('/topic/laconica.allusers',
$notice->content,
array(
'profile_id' => $notice->profile_id,
'tags' => implode($tags,' ')
)
);
common_log(LOG_DEBUG, 'sent to catch-all topic ' . $notice->id);

```

The Stomp client is really similar to the one of the previous post, but it specifies the additional header "selector" passed when subscribing.

The selector here is "tags LIKE %dent%". This matches all the posts that contains the tag #dent. Substitute it to match the tag you want...

```php

<?php

require_once "Stomp.php";

$con = new Stomp('tcp://localhost:61613');
if (!$con->connect())
    print 'conn failed';

$what = '/topic/laconica.allusers';

$query = 'tags LIKE \'%dent%\'';

if (!$con->subscribe($what,array("selector" => $query)))
    print "sub failed";
else
    print "sub to ".$what." successful\n";

while (true) {
    $msg = $con->readFrame();
    if ($msg) {
        print $msg->headers['profile_id'].": ".$msg->body. " -- ";
        print "msg_time:".$msg->headers['created']." ";
        print "tags: ".$msg->headers['tags']."\n";
        $con->ack($msg);
    }
}

$con->disconnect();
?

```