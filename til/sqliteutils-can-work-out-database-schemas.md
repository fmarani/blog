---
title: "Sqlite-utils can work out database schemas"
date: "2023-01-20T17:52:42+01:00"
tags: []
---

One thing that is annoying sometimes, when you want to quickly analyze with SQL some data, is that you likely have to work out what the schema is before running any insert.

With [sqlite-utils](https://sqlite-utils.datasette.io/), you can skip that. I found it particularly helpful when using the [bulk inserts](https://sqlite-utils.datasette.io/en/stable/python-api.html#bulk-inserts) function: it will work out the schema by analyzing the first 100 documents (that number is customizable).

```python
from sqlite_utils import Database
from sqlite_utils.utils import chunks

db = Database("example.db")


def get_data():
    yield {"a": 1, "b": 2}
    yield {"a": 1, "c": 3}
    yield {"a": 1, "d": 4}
    yield {"a": 1, "b": 5}
    yield {"a": 1, "b": 6}
    yield {"a": 1, "b": 7}


if __name__ == "__main__":
    for chunk in chunks(get_data(), 100):
        db["data"].insert_all(chunk)
```

The script above will work out that the table has 4 columns and they are of type integer.

```sh
> sqlite3 example.db
sqlite> select * from data;
a  b  c  d
-  -  -  -
1  2
1     3
1        4
1  5
1  6
1  7
sqlite> .schema
CREATE TABLE [data] (
   [a] INTEGER,
   [b] INTEGER,
   [c] INTEGER,
   [d] INTEGER
);
```

The script above can also be adapted to work on nested data, using the included `flatten()` function:

```python
from sqlite_utils import Database
from sqlite_utils.utils import chunks, flatten

db = Database("example.db")


def get_data():
    yield {"a": 1, "b": 2}
    yield {"a": 1, "c": 3}
    yield {"a": 1, "d": 4}
    yield {"a": 1, "b": {"sub_b": 5}}
    yield {"a": 1, "b": {"sub_b": 6}}
    yield {"a": 1, "b": {"sub_b_2": 6}}
    yield {"a": 1, "b": 7}


if __name__ == "__main__":
    for chunk in chunks((flatten(row) for row in get_data()), 100):
        db["flatten_data"].insert_all(chunk)

```

It will turn each level into a flat space using the `_` delimiter.

```sh
sqlite> select * from flatten_data;
a  b  c  d  b_sub_b  b_sub_b_2
-  -  -  -  -------  ---------
1  2
1     3
1        4
1           5
1           6
1                    6
1  7
```
