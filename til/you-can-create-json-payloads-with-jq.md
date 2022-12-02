---
title: "You can create JSON payloads with JQ"
date: "2022-11-22T23:01:57+01:00"
tags: ["jq"]
---
[JQ](https://stedolan.github.io/jq/) can be used to create JSON objects of a certain shape, with the help of a few command line options.

You can use `--argjson` to load JSON objects into variables that can then be referenced by `$name`. Here's an example:

```
> jq -n --argjson vars '["a", "b", "c"]' '{"vars": $vars}'
{
  "vars": [
    "a",
    "b",
    "c"
  ]
}
```

(The `-n` option is to avoid `jq` attempting to read files as input)

Similarly, you can use the option `--slurpfile` to load a json file in a variable (arrays only):

```
> cat vars.json 
["a", "b", "c"]

> jq -n --slurpfile vars vars.json '{"vars": $vars}'
{
  "vars": [
    [
      "a",
      "b",
      "c"
    ]
  ]
}
```

All this can be extended to manipulate the keys too. Here's an example (written in fish shell)

```
> cat vars.json
{
  "key1": "val1"
}

> set vars (cat vars.json)
> jq -n --argjson vars "$vars" '{"key2": "val2"} + $vars'
{
  "key2": "val2",
  "key1": "val1"
}
```

Or create a simple key override system:

```
> cat vars.json
{
  "key2": "val1"
}

> set vars (cat vars.json)
> jq -n --argjson vars "$vars" '{"key2": "val2"} + $vars'
{
  "key2": "val1"
}

> jq -n --argjson vars "$vars" '$vars + {"key2": "val2"}'
{
  "key2": "val2"
}
```
