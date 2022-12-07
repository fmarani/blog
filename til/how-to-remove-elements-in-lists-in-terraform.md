---
title: "How to remove elements from lists in Terraform"
date: "2022-12-07T22:20:44+01:00"
tags: ["terraform"]
---

You can remove specific elements from a list or a set with this syntax

```hcl
$ terraform console

> [for i in [1, 2, 3, 4, 5]: i if i != 3]
[
  1,
  2,
  4,
  5,
]
> toset([for i in toset([1, 2, 3, 4, 5]): i if i != 3])
toset([
  1,
  2,
  4,
  5,
])
```

There's also a function that eliminates all the false-y values in a list.

```hcl
> compact([1, 2, null, 3])
tolist([
  "1",
  "2",
  "3",
])
```

