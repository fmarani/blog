+++
date = "2009-03-15 19:57:51+00:00"
title = "About the use of queues and pubsub in Laconi.ca"
tags = ["laconica", "pubsub", "stomp"]
description = "Integrating message brokers and pub-sub into a microblogging service"
+++

Lately i have been working on the idea of queues and pubsub mechanisms and how it is possible to integrate them in a microblogging service. I am fascinated by messaging protocols and event pushing!

Let me say that XMPP is in my opinion the protocol of the future, however its pubsub implementation is quite complex if compared to what STOMP offers, and I didn't find any mature PHP library.

AQMP and STOMP are more suitable for internal processing, while XMPP is the perfect option for exposing data to the outside world and perhaps to connect desktop clients with microblogging services.

Apart from my opinions, STOMP is a mature protocol with a PHP library that works pretty well and  Apache ActiveMQ, the message broker, offers access using several protocols.

<strong>INTRODUCING A MESSAGE BROKER IN LACONI.CA</strong>

If queues are enabled in laconi.ca, it is possible to modify common_enqueue_notice() (called after the storage of the dent) in order to push the dent in the 4 queues that the software uses (OMB, jabber, sms, public), or simply push the dent in one and configure 3 mirror queues.

In this way the internal queue system is not used. Queue_item::top() has potential race conditions and polls the db every 5 seconds. That means that if we're lucky we get the message quickly, if unlucky in 5 seconds. Latency could even be something secondary, but the system now is pretty inefficient.

If laconi.ca passes the message to an external broker, delivery would be more efficient and it is a piece of code that the community wouldn't have to maintain.

The downside of this is that another software is on the list of requirements. However, if you have the possibility to run queuehandlers in background, it probably means you own the server and you can afford to install a message broker. Queues can still be disabled and the system still works without queues and message brokers, the only difference is that everything is done synchronously.

<strong>WITH A MESSAGE BROKER, PUBSUB COMES FOR FREE</strong>

Another feature of ActiveMQ is the use of "topics". The main differences between queues and topics are that in the queues messages are sent to only one consumer (precisely, round-robin among consumers) and messages are persistent (stored internally while waiting consumers to connect). Topics are the opposite, the same message is sent to all its consumers that are currently connected to the broker.

Topics could be used for introducing a publish-subscribe system in Laconi.ca. In common_enqueue_notice() with only some lines of code it is possible to push each dent to topics such as "/topic/laconica.user.IDUSER", "/topic/laconica.allusers" or do more complex association like "/topic/laconica.group.IDGROUP" and "/topic/laconica.tag.TAGNAME".

With a topic dedicated to a group and using the XMPP endpoint of ActiveMQ, you can also gain MUC support in Laconi.ca (only read-only if there isn't an handler)

Offering pubsub using ActiveMQ and STOMP calls is very easy, however i am not sure how interoperable this solution could be. I did not find any XMPP/Pubsub interface for ActiveMQ, although topics could be easily mapped to XMPP/Pubsub nodes.

If the pubsub notifications have to be XMPP based, i see two solutions: write a wrapper that gets all the messages via an ActiveMQ queue and speaks XMPP with ejabberd, or forget about ActiveMQ and use XMPP requests directly, perhaps using an AtomPub interface.

<strong>POSSIBLE FUTURE DIRECTIONS</strong>

Integrating queues at the end of the stack is not going to help much in terms of performance or flexibility of the whole system, but it's a first step and, as they're used marginally, they're still an optional requirement.

With all these ideas around, like offering XMPP MUC support, AtomPub interfaces, XMPP/Pubsub output, etc.. in the future the system would have to be "decoupled".

An input system that pushes dents in a queue as quickly as possible. The main Laconi.ca logic that works in the background and asynchronously. The internal logic will then push the info to queue handlers for real-time delivery AND store the dents in the DB. The main website will still poll data from the DB, with all the necessary caching layers, OR/AND poll directly the message broker for the required type of dent (see the list of topics mentioned before) via AJAX calls (ActiveMQ has support for that).

Any feedback is appreciated, or suggestions on things i might have overlooked! I am not an expert of message queue system so many of the things i have said may seem obvious, but not to someone who has a background of normal website and MVC development so i clearly stated all the steps...

<strong>WHAT I DID</strong>

<code>
function common_enqueue_notice($notice)
{
if (common_config('queue','subsystem') == 'stomp') {
// use an external message queue system via STOMP
require_once("Stomp.php");
$con = new Stomp(common_config('queue','stomp_server'));
if (!$con->connect()) {
common_log(LOG_ERR, 'Failed to connect to queue server');
return false;
}
$queue_basename = common_config('queue','queue_basename');
foreach (array('jabber', 'omb', 'sms', 'public') as $transport) {
if (!$con->send(
'/queue/'.$queue_basename.'-'.$transport, // QUEUE
$notice->id,            // BODY of the message
array (                 // HEADERS of the msg
'created' => $notice->created
))) {
common_log(LOG_ERR, 'Error sending to '.$transport.' queue');
return false;
}
common_log(LOG_DEBUG, 'complete remote queueing notice ID = ' . $notice->id . ' for ' . $transport);
}
$con->send('/topic/laconica.'.$notice->profile_id,
$notice->content,
array(
'profile_id' => $notice->profile_id,
'created' => $notice->created
)
);
$con->send('/topic/laconica.allusers',
$notice->content,
array(
'profile_id' => $notice->profile_id,
'created' => $notice->created
)
);
$result = true;
}
else {
// in any other case, 'internal'
foreach (array('jabber', 'omb', 'sms', 'public') as $transport) {
$qi = new Queue_item();
#OTHER OLD CODE...
</code>

This code sends the dent to 4 queues and 2 topics. Queues are used by the 4 background queuehandlers while 2 topics offer a simple pubsub service to either a single userid or to all of them (public timeline).

As regards queues, queuehandler.php has to be modified:
<code>
# called by run()
function stomp_dispatch() {
require("Stomp.php");
$con = new Stomp(common_config('queue','stomp_server'));
if (!$con->connect()) {
$this->log(LOG_ERR, 'Failed to connect to queue server');
return false;
}
$queue_basename = common_config('queue','queue_basename');
// subscribe to the relevant queue (format: basename-transport)
$con->subscribe('/queue/'.$queue_basename.'-'.$this->transport());
do {
$frame = $con->readFrame();
if ($frame) {
$this->log(LOG_INFO, 'Got item enqueued '.common_exact_date($frame->headers['created']));
// XXX: Now the queue handler receives only the ID of the
// notice, and it has to get it from the DB
// A massive improvement would be avoid DB query by transmitting
// all the notice details via queue server...
$notice = Notice::staticGet($frame->body);
if ($notice) {
$this->log(LOG_INFO, 'broadcasting notice ID = ' . $notice->id);
$result = $this->handle_notice($notice);
if ($result) {
// if the msg has been handled positively, ack it
// and the queue server will remove it from the queue
$con->ack($frame);
$this->log(LOG_INFO, 'finished broadcasting notice ID = ' . $notice->id);
}
else {
// no ack
$this->log(LOG_WARNING, 'Failed broadcast for notice ID = ' . $notice->id);
}
$notice->free();
unset($notice);
$notice = null;
} else {
$this->log(LOG_WARNING, 'queue item for notice that does not exist');
}
}
} while (true);
$con->disconnect();
}
</code>

Here there's the code for a simple pubsub consumer
<code>
require_once "Stomp.php";
$con = new Stomp('tcp://localhost:61613');
if (!$con->connect())
print 'conn failed';
$what = '/topic/laconica.2';
if (!$con->subscribe($what))
print "sub failed";
else
print "sub to ".$what." successful\n";
while (true) {
$msg = $con->readFrame();
if ($msg) {
print $msg->headers['profile_id'].": ".$msg->body. " -- ";
print "msg_time:".$msg->headers['created']." ";
print "received:".date("Y-m-d H:i:s")."\n";
$con->ack($msg);
}
}
$con->disconnect();
</code>

Except the last bit, all this code is on the fmarani-clone of the dev repo on gitorious, branch 0.8.x