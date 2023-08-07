---
title: "Terraform can automatically dedent multiline strings"
date: "2023-08-07T22:51:30+02:00"
tags: []
---

You can use [heredoc markers](https://developer.hashicorp.com/terraform/language/expressions/strings#heredoc-strings) to define strings in HCL that span multiple lines. There is also a way to automatically strip out all extra indentation that may have in it, by using the `<<-` operator.

To test this, you can create in an empty dir a `main.tf` file with these contents:
```
output "heredoc-raw" {
  value = <<EOT
      this
        is
          indented
  EOT
}

output "heredoc-indented" {
  value = <<-EOT
      this
        is
          indented
  EOT
}
```

and then run these to get the outputs:
```
> terraform apply
...
> terraform output -raw heredoc-indented
this
  is
    indented
> terraform output -raw heredoc-raw
      this
        is
          indented
```


This helps when you want to keep your code nicely indented, regardless of whether a specific line is an instruction or data.
