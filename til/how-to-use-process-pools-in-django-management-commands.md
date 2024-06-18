---
title: "How to use process pools in Django management commands"
date: "2024-06-18T10:58:31+02:00"
tags: ["django", "multiprocessing", "concurrency"]
---

Sometimes you have to run things concurrently, and a few of those times you have to control the exact concurrency level. In a non-distributed system, controlling concurrency is easy.

Python has the `multiprocessing` library, and a whole collection of future executors, that can be used to do just that, but there are a few caveats with process-based concurrency:
- each Django process has a lot of global state that needs initializing
- message passing between processes can only happen if everything passed can be pickled

I found that this snippet of code works well:

```python
import concurrent.futures

import django
from django.core.management.base import BaseCommand

from main.models import Thing

class Command(BaseCommand):
    @staticmethod
    def run_task(thing_id):
        thing = Thing.objects.get(id=thing_id)
        print(f"Running thing {thing}")

        # do your computation on thing here

        print(f"{thing} done")

    def handle(self, *args, **options):
        concurrency_level = 2
        things = Thing.objects.all()

        print("starting")
        with concurrent.futures.ProcessPoolExecutor(max_workers=concurrency_level, initializer=django.setup) as executor:
            futures = [executor.submit(self.run_task, thing.id) for thing in things]
        concurrent.futures.wait(futures, timeout=60*60)
        for future in futures:
            if not future.done():
                future.cancel()
```
