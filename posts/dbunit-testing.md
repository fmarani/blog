+++
date = "2010-10-17 13:09:26+00:00"
title = "Dbunit testing"
tags = ["php", "unit-testing"]
description = "Testing PHP database code with PHPUnit and DBUnit"
+++

This article is about PHPUnit used in conjunction with DBUnit to test PHP code that interacts with a database server. 

Please note that DBUnit is able to load and unload sets of data to the db but does not handle table creation and queries that alter structures. This is responsibility of an ORM or an initial sql script that creates/rebases the initial environment.

Code i wrote is run against a very simple ORM implementation we currently use in my workplace. Code should be simple enough to follow.

<strong>DB Unit test</strong>

A dbunit test is basically a unit-test which inherits from PHPUnit_Extensions_Database_TestCase and declares two more methods: getConnection() and getDataSet(). The first one must return the dbunit wrapper of PDO and the second a dataset representation created with create*Dataset() functions.

```php
class TestAddress extends PHPUnit_Extensions_Database_TestCase
{
    private $fixture_addressId;
    private $fixture_location;

    public function setUp()
    {
        parent::setUp();
        $this->fixture_addressId = "5";
        $this->fixture_location = "Melbourne";
    }

    protected function getConnection()
	{
		$pdo = getPdo(); // replace this code
		return $this->createDefaultDBConnection($pdo, 'testdb');
	}

    protected function getDataSet()
    {
        return $this->createFlatXMLDataSet(dirname(__FILE__).'/../fixtures/db-addresses.xml');
    }

    public function testBasicFixtureLoading()
    {
        $mapper = new address_Mapper();
        $address = $mapper->findById($this->fixture_addressId);
        
        $this->assertEquals($address->addressLine3, $this->fixture_location);
    }

    public function testSave()
    {
        $mapper = new address_Mapper();
        $address = $mapper->findById($this->fixture_addressId);
        $address->addressLine3 = "London";
    	$mapper->save($address);
    	unset($address);
        $address = $mapper->findById($this->fixture_addressId);
    	$this->assertEquals("London", $address->addressLine3);
    }
}
```

<strong>model object</strong>

Model objects are a representation of data. They are basically a data container. They must not contain any integration logic (ex. database queries), that is responsibility of mapper objects.

```php
class Address extends Model
{
	public function __construct()
	{
		parent::__construct('addressId');
		$this->setFieldNames(array(
			'addressId',
			'firstName',
			'lastName',
			'addressLine1',
			'addressLine2',
			'addressLine3',
			'addressLine4',
			'state',
			'postCode',
			'country',
			'createdDate'
			));
	}
}
```

<strong>mapper object</strong>

Responsibility of mapper object is to populate and return correspondent models of data. In this case it returns address models. Our mapper class already offers generic find()/insert()/update()/delete() operation but you may want to extend it to use different find methods.

```php
class address_Mapper extends Mapper
{
	const STORAGE_NAME = 'Addresses'; // table name

	public function __construct()
	{
		parent::__construct(getPdo(), self::STORAGE_NAME, 'addressId');
	}

    public function findById($addressId)
    {
        $identity = array('addressId' => $addressId);
        $model = new Address;
        parent::find($identity, $model);
        return $model;
    }
}
```

<strong>Fixture datasets</strong>

These are our test data. Each dbunit test has his own dataset. There are many formats available for PHPUnit, the one here is called FlatXMLDataset, which is really simple.

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<dataset>
 <Addresses
   addressId="5"
   firstName="myName"
   lastName="mySurname"
   addressLine1="myAddr1"
   addressLine2="myAddr2"
   addressLine3="myAddr3"
   addressLine4="Melbourne"
   state=""
   country="AU"
   postCode="3400"
   createdDate="18:16:19 2009-10-18"
  />

 <Addresses
   addressId="6"
   firstName="Another"
   lastName="Person"
   addressLine1="Somewhere"
   addressLine2=""
   addressLine3="London"
   addressLine4=""
   state=""
   country="UK"
   postCode="XXX111"
   createdDate="18:00:19 2009-10-18"
  />
</dataset>
```

Each child tag of <dataset> is <TABLE_NAME column1="value"> kind of syntax. Nothing more than that, no structure only data.

<strong>Bootstrapping</strong>

As we said there is no table definition loading by default in DBunit. Initial environment must be setup before the dbunit test runs and this can be done using PHPUnit bootstrap files (see --bootstrap option).

It is not necessary to drop and recreate tables everytime but highly advisable, there could be cases in which the test is supposed to fail but it does not because it reads data that should not be in the database. That is why we need to control execution environment as much as possible.

```php
define("FIXTURE_DB_REBASE", dirname(__FILE__)."/fixtures/db-rebase.sql");

// To test database-dependent classes you need a local database with the following settings
$host = 'localhost';
$user = 'unittests';
$password = 'myPassword';
$dbName = 'app_UnitTests';

// Create a database adapter
try {
    $dbh = new PDO("mysql://".$host."/".$dbName, $user, $password);
} catch (PDOException $e) {
    echo 'Connection failed: ' . $e->getMessage();
}

// Ensure database credentials work
try {
    $results = $dbh->query("SHOW TABLES")->fetchAll();
} catch (PDOException $e) {
    echo "You need to create a local test database - see bootstrap.php for more details\n";
    echo "Connection error: ".$e->getMessage()."\n";
    exit;
}

// rebase the database
$dbh->query(file_get_contents(FIXTURE_DB_REBASE))->closeCursor();
```

<strong>DB rebase SQL fixture</strong>

```sql
--
-- Table structure for table 'Addresses'
--

DROP TABLE IF EXISTS Addresses;
CREATE TABLE Addresses (
  addressId int(10) unsigned NOT NULL auto_increment,
  firstName varchar(128) NOT NULL,
  lastName varchar(128) NOT NULL,
  addressLine1 varchar(256) NOT NULL,
  addressLine2 varchar(256) NOT NULL,
  addressLine3 varchar(256) NOT NULL,
  addressLine4 varchar(256) NOT NULL,
  state varchar(128) NOT NULL,
  country varchar(128) NOT NULL,
  postCode varchar(32) NOT NULL,
  createdDate datetime NOT NULL,
  PRIMARY KEY  (addressId)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
```
