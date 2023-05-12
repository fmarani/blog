---
title: "What is the difference between include and template functions in helm"
date: "2023-05-12T11:08:12+02:00"
tags: []
---

The difference between the two functions is that the result of `template` cannot be chained with another function, while `include` can.

Please note that the `template` function is included in the Go language, while the `include` function is only available in Helm.

Here is an example Helm template:
```yaml
{{- define "greet" }}hello {{ . }}{{- end }}
---
greetInclude: {{ include "greet" .Values.name | title }}
greetTemplate: {{ template "greet" .Values.name | title }}
```

Feeding in these values:
```yaml
---
name: johnny
```

This is the output:
```yaml
---
greetInclude: Hello Johnny
greetTemplate: hello Johnny
```

Notice that the `title` function, which capitalizes the words passed in, is getting the whole output of the greet definition, when using `include`.

When using `template`, the function is only receiving the value of `.Values.name`. That's is why `include` is capitalizing both words `Hello Johnny`, while template only the second word.

If we wanted to, we could make `include` behave like `template` if we put some extra parenthesis:
```yaml
{{- define "greet" }}hello {{ . }}{{- end }}

---
greetInclude: {{ include "greet" (.Values.name | title) }}
greetTemplate: {{ template "greet" .Values.name | title }}
```

Which would result in a identical output:
```yaml
---
greetInclude: hello Johnny
greetTemplate: hello Johnny
```
