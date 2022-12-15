---
title: "To use 'script' to record terminal input output"
date: "2022-12-15T23:30:45+01:00"
tags: ["ubuntu", "cli"]
---
`script` is a binary included in Ubuntu that can be used to record activity in a shell. It can optionally record timings too, to get exactly the same experience when replaying the recorded activity.

```
> script 
Script started, output log file is 'typescript'.
Welcome to fish, the friendly interactive shell
flagzeta@penguin ~/w/blog (main)> hello
fish: Unknown command: hello
flagzeta@penguin ~/w/blog (main) [127]> exit
Script done.
```

By default it logs everything to a file called `typescript`:

```
flagzeta@penguin ~/w/blog (main)> cat typescript 
Script started on 2022-12-15 23:37:15+01:00 [TERM="xterm-256color" TTY="/dev/pts/3" COLUMNS="107" LINES="50"]
Welcome to fish, the friendly interactive shell
flagzeta@penguin ~/w/blog (main)> hello
fish: Unknown command: hello
flagzeta@penguin ~/w/blog (main) [127]> exit

Script done on 2022-12-15 23:37:23+01:00 [COMMAND_EXIT_CODE="127"]
```
