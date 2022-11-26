+++
categories = []
tags = ["microservices", "grpc", "python", "architecture"]
title = "Using GRPC with Django"
date = "2018-01-16T15:41:15Z"

+++

GRPC is an implementation of an RPC system, created by Google and Square, that leverages the low-level features of HTTP/2. It has many interesting properties, like bi-directionality, efficiency, and support from many languages. RPC interfaces are declared in a special "proto" file in a readable way, which makes it, in part, self-documenting. These proto files are then used to generate client and server stubs, which is very convenient.

GRPC is a good choice for internal and performance-sensitive APIs. It cannot (yet) be used from the browser.

Here I am using as a reference a system I built for monitoring purposes. It is an internal API that receives a list of sensors everytime a new client is run, followed by sensor activations from every sensor connected to every client when the sensors are triggered. The exact nature of this is not very important, as long as mechanically it is clear.

When using this system, the generated stubs and the message descriptors need to be shared between client and server projects, therefore for these it is better to create a Python package. Another reason for this is that proto files in turn can have packages and imports, and when the compiler compiles proto files, those concepts are translated into Python modules and imports following the GRPC convention.

Shared package
===

I will be using as example a toy project called `slimmer`. We will have a client project, a server project and a shared package, which will contain the stubs. To start with, create an empty folder with a minimal `setup.py` file:

```python
from setuptools import setup

setup(name='slimmer_grpc',
      version='0.1',
      description='Slimmer client/server stubs',
      url='http://github.com/fmarani/slimmer_grpc',
      author='Federico Marani',
      author_email='flagzeta@gmail.com',
      license='MIT',
      packages=['slimmer_grpc'],
      install_requires=[
          'grpcio==1.8.3'
      ],
      zip_safe=False)
```

That is the minimum required to make this package installable. It is missing a dependency that is required when you are developing. We will add that through a `requirements-dev.txt` file:

```
grpcio-tools==1.8.3
```

Second step you need to create your proto file. I am using an example which is more sophisticated than an "Hello world", hope it is clear anyway.

I am placing this file inside a special folder called `proto` with a folder structure that mirrors the package hierarchy. In this case, that would be `proto/slimmer_grpc/main.proto`.

```protobuf
syntax = "proto3";

package slimmer_grpc;

service Main {
  rpc ping (Ping) returns (Pong) {}
  rpc new_system_run (SystemRun) returns (SystemRunResponse) {}
  rpc new_activation (Activation) returns (ActivationResponse) {}
}

message Ping {
  string message = 1;
}

message Pong {
  string message = 1;
}

message SystemEntity {
  string category = 1;
  string name = 2;
  string identity = 3;
}
message SystemRun {
  string system_id = 1;
  repeated SystemEntity entities = 2;
}
message SystemRunResponse {
  string run_id = 1;
}

message Activation {
  string system_id = 1;
  string run_id = 2;
  SystemEntity entity = 3;
}
message ActivationResponse {
  bool success = 1;
}
```

After you have written all this, now it is time to generate the code. From the folder that contains `setup.py`, run the following command.

```
python -m grpc_tools.protoc -I proto --python_out=./ --grpc_python_out=./ proto/slimmer_grpc/main.proto
```

This command will generate a new folder called `slimmer_grpc`. This is the folder that we want to distribute.

There are several methods of distributing packages, some Python specific (e.g. Pypi), some Git specific (e.g. submodules), some more bare-bones (e.g. have it in a folder in the same repo). How you decide to do this is up to you. In the rest of the article we assume the package is in a subfolder of repository. A structure like this will do:

```
/repo/client_project - the python client
/repo/slimmer_grpc - the shared library
/repo/slimmer - server code
```


Django server
===

First of all, you have to install the package we created above. In order to proceed fast, we can install it in editable mode. Once activated the virtualenv of the server project (in the filesystem structure above it would be "slimmer"), this is the command to install it:

```
pip install -e ./slimmer_grpc/
```

Next step is to focus on integration with the server. Django is a WSGI application, which is normally run by a WSGI HTTP server like Gunicorn or uWSGI. Both Gunicorn and uWSGI have their own event loop, which are clashing with the GRPC event loop.

Gevent may be used here to make the two cooperate, but I am reluctant to explore that path. The more complex your Django (or GRPC) stack becomes the easier is to find a piece of software that is not gevent-friendly. Also, I am not a fan of its approach.

I am choosing a way that is a lot simpler and more basic: have two separate processes, with two event loops. In order to do that, they must be independent. They will listen to different ports, and they will have separate lifecycles (startup/shutdown/etc).

What we need is a Django management command that instead of entering the WSGI loop, enters in the GRPC loop.

```python
from concurrent import futures
import time
import grpc
from contextlib import contextmanager
from django.core.management.base import BaseCommand, CommandError
from slimmer_grpc import main_pb2_grpc, main_pb2
from main import models


class MainServicer(main_pb2_grpc.MainServicer):
    def ping(self, request, context):
        return main_pb2.Pong(message=request.message)

    def new_system_run(self, request, context):
        # your code here
        return main_pb2.SystemRunResponse(run_id="your id")

    def new_activation(self, request, context):
        # your code here
        return main_pb2.ActivationResponse(success=True)


_ONE_DAY_IN_SECONDS = 60 * 60 * 24

@contextmanager
def serve_forever():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    main_pb2_grpc.add_MainServicer_to_server(MainServicer(), server)
    server.add_insecure_port('[::]:50051')
    server.start()
    yield
    server.stop(0)

class Command(BaseCommand):
    help = 'api server'

    def handle(self, *args, **options):
        with serve_forever():
            self.stdout.write(self.style.SUCCESS('Successfully started grpc server '))
            try:
                while True:
                    time.sleep(_ONE_DAY_IN_SECONDS)
            except KeyboardInterrupt:
                pass
```

This is enough to start serving GRPC requests!


Python client
===

Using the client does not require any special treatment. It is just a class that needs to be called. Once installed the shared package in the virtualenv of the client, it is quite straightforward.


```python
from slimmer_grpc import main_pb2_grpc, main_pb2
import grpc

def get_client():
    channel = grpc.insecure_channel("1.2.3.4:50051")
    client = main_pb2_grpc.MainStub(channel)
    response = client.ping(main_pb2.Ping(message='test'))
    if response.message == "test":
        return client
```

That is a starting point. This will need to be extended with exception handling, etc...


Production
===

Whatever system you use to run this:

- Highly advised to run the Gunicorn part under Nginx. A similar setup is not necessary for the GRPC server.
- Both processes need to be run under a supervisor. If you are running this in Heroku, the GRPC server needs to be in a separate dyno.
- You may be able to use a recent version of Nginx to do virtual hosting + reverse proxying for GRPC.
