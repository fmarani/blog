+++
title = "Minimal Helm resource generator"
tags = ["helm", "kubernetes"]
description = "Using for loops to generate lightly customized resources"
date = "2023-05-22T18:19:15Z"
+++

At work we run a lot of deployments/jobs in a given Kubernetes cluster, and many of them are slight copies of each other. A good example of this is running a series of cronjobs: as a rule you want them to run with the same setup, except for the command and the time specifier.

For these cases of "many of the same thing", this is the base Helm template that we tend to follow. Here presented in a pseudocode fashion:

```
{{- define "greet" }}
{{- $root := index . 0 }}
{{- $item := index . 1 }}
{{- $prefix := $item.prefix | default $root.Values.prefix }}
{{- $prefix }} {{ $root.Values.name }}
{{- end }}

{{- range $key, $value := .Values.customizations }}
---
kind: Greeter
apiVersion: 1
metadata:
  name: {{ $key }}
spec:
  phrase: {{ include "greet" (list $ $value) }}
{{- end }}
```

If you run the above with the following values:

```yaml
name: "Joe"
prefix: "Hello"

customizations:
  informal:
    prefix: "Heya"
  normal: {}
  formal:
    prefix: "Dear"
```

You would get this result:

```yaml
---
kind: Greeter
apiVersion: 1
metadata:
  name: formal
spec:
  phrase: Dear Joe
---
kind: Greeter
apiVersion: 1
metadata:
  name: informal
spec:
  phrase: Heya Joe
---
kind: Greeter
apiVersion: 1
metadata:
  name: normal
spec:
  phrase: Hello Joe
```

This allows us to generate big quantities of Kubernetes manifests while keeping our value files free from lots of repetition.

Explanation
---

The customizations here are driven by a map (a.k.a. dictionary in Python): one "Greeter" in the results is generated for every entry in the "customizations" map.

Each map entry is a tuple of (name, value). The name is used to name the Greeter (see `metadata.name`). The value is passed to the greet function.

In the Go template language, you can define functions. Even though functions can only take one parameter, we can get around this limitation by passing a list object. This list object is constructed when calling `include` and deconstructed just after the `define` definition.

The `greet` function in our example needs to be aware of the original template context that this chart was rendered with. That original template context, which in the default block would be called `.`, within a `range` block is renamed to `$`. That is why the arguments of the `include` functions are `(list $ $value)`, but outside of the `range` block it is referred to `.` (an example is the `.Values.customizations` reference).

Inside the `greet` function we deconstruct the list using `index . N`, again referencing the `.` context. At this level it is not the original template context anymore but the context passed in to the include (the `list` object). The deconstruction in our case is simply naming the positional arguments of the list to something more explicit.

The `greet` function returns a concatenated string of `$prefix` and `$root.Values.name`. The `$prefix` is looked up inside the customization block first and, if that does not evaluate to anything, it falls back to the default prefix.