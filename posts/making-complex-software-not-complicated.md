+++
date = "2010-10-05 20:32:05+00:00"
title = "Making complex software not complicated"
tags = ["dependency injection", "unit-testing"]
+++

I'd like to share my thoughts with you about approaching difficult problems in software development. This is pretty much what i came to realize after many years of development.

A difficult problem is usually divisible in several simple problems, but when developing software you stack up problems and every problem relies on the solution of the sub-problem.

Example (a common order visualizer)

<pre>
1st level of the stack:
1) display_order_in_xml() (relies on read_order())
1) display_order_in_json() (relies on read_order())
2nd:
2) read_order() (relies on read_orderitems() and an internal calculate_delivery())
3rd:
3) read_orderitems() (relies on items_mapper::find() OR read_items_from_external_shop())
4th - case 1 - items_mapper
4) items_mapper::find() (relies on a db_Adapter)
5) db_Adapter (no dependencies)
4th - case 2 - read_items_from_external_shop()
4) read_items_from_external_shop() (relies on json_call())
5) json_call() (depends on http class for sending requests)
6) http class (no dependencies)
</pre>

Solution here is to isolate each bit, and being able to feed a fixed solution of the sub-problem to the current problem. Isolating each bit allows us to solve one problem at a time, being able to pass dependencies to the constructor gives us the possibility to pass already computed solutions of the sub-problems.


```php
class OrderDisplayer {
 public function __construct($orderReader) {
  $this->orderReader = $orderReader; // without orderReader, this class has no reason to exist
 }
 public function toXml($orderNumber) {
  return $this->doMagic($this->orderReader->read_order($orderNumber));
 }
}

class OrderReader {
 public function __construct($itemsReader, $calculator) {
  $this->itemsReader = $itemsReader; // same here, without these 2 objects this class has no reason to exist
 }
 public function read($orderNumber) {
  $items = $this->itemsReader->read_orderitems($orderNumber));
  $delivery = $this->calculator->applyCrazyDeliveryCosts($items); // this will depend on a currency converter, which depends on a httpclient which connects to a webservice :)
 }
}

class ItemsReader {
 public function __construct($itemsMapper, $remoteItemsReader) {
  $this->itemsMapper = $itemsMapper; // same story
  $this->remoteItemsReader = $remoteItemsReader;
 }
 public function read($orderNumber) {
    $conditions = array(orderNumber == $orderNumber, itemCost > 0, day == today);
    $items = $this->itemsMapper->find($conditions);
    if (!$items) {
      $items = $this->remoteItemsReader->find($conditions);
    }
    return $items;
 }
}


class ItemsMapper {
 public function __construct($dbAdapter) {
  $this->dbAdapter = $dbAdapter; // same story
 }
 public function find($conditions) {
    return $this->dbAdapter->query("SELECT FROM Items WHERE ".$this->getWhere($conditions));
 }
}


class remoteItemsReader {
 public function __construct($jsonRpcService) {
  $this->jsonRpcService = $jsonRpcService; // same story
 }
 public function  read_items_from_external_shop($conditions) {
    $this->serverList = array("ecommerce.johnsmith.co.uk", "www.bestshopever.com.au");
    foreach ($this->serverList as $server) {
     $items = $this->jsonRpcService->json_call($server, $this->getJsonBody($conditions));
     if (count($items) > 0)
       return $items;
    }
 }
}


class JsonRpcService {
 public function __construct($httpService) {
  $this->httpService = $httpService; // same story
 }
 public function json_call($server, $jsonCall) {
   $this->httpService->connect($server);
    return $this->httpService->postAndReadAnswer("/jsonrpc.php", $jsonCall);
 }
}
```

Each of these classes are unit-testable, which represents the software unit of measurement of isolation. Ability to feed intermediate solutions to the dependent problems comes from mocked objects:

Example 1:

```php
class MockJsonRpcService {
  public function json_call($server, $jsonCall) {
   return array($item1, $item2);
 }
}
$remoteReader = new remoteItemsReader(new MockJsonRpcService());
assert($remoteReader->read_items_from_external_shop() == array($item1, $item2));
// pseudo code here... see phpunit manual..
```

example 2:

```php
class MockOrderReader {
 public function read($orderNumber) {
  return array($itemA, $itemB, $itemC);
 }
}
$orderDisplayer = new OrderDisplayer(new MockOrderReader());
assert($orderDisplayer->toXml(1), "ABC");
```


And so on... having followed the constructor-setter approach we can now test each bit separately. Then, everytime you need a real OrderDisplayer you have to type all this stuff:


```
$orderDisplayer = new OrderDisplayer(new OrderReader(new ItemsReader(new ItemsMapper(new db_Adapter), new RemoteItemsReader(new JsonRpcService(new HttpService))), new DeliveryCalculator()))
```

By doing this we "inverted the control"... instead of creating object inside the classes that uses them, we create them all inside the current file... but the length of this line is far from ideal. Here what comes really handy is having a Dependency Injection Framework. Internally in our company we use our own framework which is really helpful in this case: just write the xml to do the autowiring.


<code>
http.service
jsonrpc.service

db.adapter
items.mapperremote.items.reader

items.readerorder.delivery.calculator
order.reader
</code>

Done this, to use the real orderDisplayer:

<code>
$orderDisplayer = $serviceLocator->getService("order.displayer");
</code>

This is the end of the explanation. Doing in this way in my opinion makes it all less complicated (when you got your head around it), and you can still build really high level abstractions, with lots of objects calling other objects, and it's still clear what is happening.

There are some open source dependency injection frameworks available, Symfony has one for instance.

I'd like to hear from you what you think... would you solve it in another way?