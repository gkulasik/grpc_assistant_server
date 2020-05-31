# GRPC Assistant Server (GAS)

Dockerized HTTP/JSON proxy server for local grpc development without the struggles of making grpc requests, leveraging gRPCurl [https://github.com/fullstorydev/grpcurl].

## What it can do
- Generate valid, ready to copy and paste, grpcurl commands from a request using HTTP/JSON.
- Execute and parse grpc requests within a docker container and return a formatted response (plaintext or JSON).
- Perform auto-formatting of select request body fields to reduce proto format dependence (ex. Dates and Timestamps).

##  What are the benefits?
- Free choice of UI (choose your HTTP client such as Postman, Paw, etc.) and all the features they support such as saving requests, variables, and testing.
- Minimal setup required (docker).
- Craft grpc request bodies and view responses in familiar HTTP/JSON format.
- Can auto-format some specific grpc types like Date or Timestamp using familiar JSON types/structures.
- Leverage a trusted base with grpcurl. Easily works with grpc servers, with or without TLS, and no potential server compatibility issues like other grpc tools may have.
- Requests are easily portable and transferable due to the text-based nature of grpcurl and/or equivalent curl.
- No changes are required to existing proto files or servers like some other grpc tools.
- Provides best-effort hints to help debug grpc call failures.

## Quickstart

1. Install Docker for Mac (or equivalent for Windows/Linux). Ensure your docker networking is setup to allow accessing the docker container from your host environment (Mac example https://docs.docker.com/docker-for-mac/networking/#use-cases-and-workarounds).
2. Download the code via git clone: `git clone https://github.com/gkulasik/grpc_assistant_server.git`. This will create a new directory called `grpc_assistant_server` with all the necessary files.
3. `cd` into the new `grpc_assistant_server directory` and run `./start_grpc_assistant_server.sh`. The first run may take some time as the docker containers are pulled from DockerHub or built locally. Subsequent runs will be substantially faster.
4. The service should be up and running!

For a quicker start, copy and paste the curl below into your favorite HTTP/JSON client to get started! The example will not work out of the box due to the limitations of grpc. Header values need to be adjusted, see `Setup` for additional information.

If running against a remote server use that server's address for the `GRPC_META_server_address`. If running locally use `host.docker.internal:{local_service_port_#}`.

#### Sample request
```
curl --request POST 'localhost:3000/service/{{protobuf_service}}/execute/{{protobuf_method}}' \
--header 'GRPC_REQ_authorization: auth-token' \
--header 'GRPC_META_import_path: {{path_to_protos_on_local_machine}}' \
--header 'GRPC_META_service_proto_path: {{path_to_proto_service_file_within_protos_directory}}' \
--header 'GRPC_META_plaintext: false' \
--header 'GRPC_META_verbose: true' \
--header 'GRPC_META_server_address: {{grpc_server_address}}' \
--data-raw '{
    "field1": "value1",
    "field2": "value2"
}
'
```

#### Sample response
```
### Parsed Response ### 

{
    "someObject": {
        "field": "value"
    },
    "foo": "bar"
}


### Command Used ### 

grpcurl  -import-path 'import/src'  -proto 'path/to/proto/service/file/services.proto'  -H 'AUTHORIZATION:auth-token'  -v  -d '{"foo":1,"bar":"test"}'  example.com:443  com.example.proto.example.FooService/ExampleMethod 

### Hints ###

...

### Full Response ### 

Resolved method descriptor:
// Some method description
rpc ExampleMethod ( com.example.proto.example.FooService.ExampleMethod ) returns ( com.example.proto.example.FooService.ExampleResponse );

...
```


##  Setup

### Set the protos source
The service and grpcurl need to know where the proto files are located. The docker container **cannot** see files outside of its local directory. There are two options to provide the service with access to local proto files. Getting the protos config right is the most important part to ensure the service works correctly!

#### Option 1 (Ideal)
Provide access to directories outside of the service directory via docker-compose volumes. This is already configured in the docker-compose.yml file for macOS.

```
docker-compose.yml
    volumes:
      - ./:/app
      - /Users:/app/Users
```

With the default configuration (for macOS) the /Users directory will be passed to the docker container granting access to the protos. Then the paths used within the docker container will match the host system. More granularity is possible for those who choose to tinker with the volumes and related request header GRPC_META_import_path. 

grpcurl commands should work anywhere within the directory structure with the default config.

Below is an example of how to set up a request's GRPC_META_import_path with the default docker-compose.yml volumes. Assuming the protos are located in foouser's projects directory and the protos directory structure starts in the /src directory.

```
Request header sample:
--header 'GRPC_META_import_path: /Users/foouser/projects/protos/src/'
```

Ideally, volumes and import_path work so that the command returned in a response body will work when copied and pasted to the host machine with no edits required to the command. 

#### Option 2
Copy proto files/directories into the directory created by git clone. Docker and the service will have access to its directory and any child directories. 

With this option, grpcurl commands will work within the docker container but may not work on the host system.


###  Docker/Compose setup

The primary config is handled in the **docker-compose.yml** file.

- The port that the server runs at can be adjusted if you are using port 3000 for other development or services. If changing the port be sure to adjust both the command and ports config.
- The volumes section may need to be adjusted for the protos to be discovered via Docker volumes. See above in 'Set the protos source' on how to set this up.
- All other applicable docker-compose changes are available but shouldn't be necessary for general usage.

#### Building the containers

Prebuilt containers are available at Docker Hub (Still requires that the git repo is pulled): https://hub.docker.com/repository/docker/gkulasik/grpc_assistant_server

The docker containers can be built locally rather than pulled after cloning the repo by editing the docker-compose.yml file.

Remove `image: gkulasik/grpc_assistant_server...` under `web` and replace with:

```
 build:
       context: .
       dockerfile: Dockerfile
```

If building locally, avoid using the update script as it will attempt to pull the container.

## Usage
There are two primary API endpoints the service provides, `command` and `execute`. There are also three primary scripts to operate the service, `start`, `stop`, and `update`.

### Scripts
Scripts must be run within the project directory `grpc_assistant_server`.

#### Start the service

`./start_grpc_assistant_server.sh`

Will start the Rails server and run migrations against the internal Sqlite3 DB. Available at localhost:3000 by default. On the first run, the docker containers will be pulled.

If this script fails rerunning it may help get the application to start successfully.

#### Stop the service

`./stop_grpc_assistant_server.sh`

Will shutdown and remove the service container.

#### Update the service

`./update_grpc_assistant_server.sh`

Will stop the service, git pull the latest changes, and repull the docker container.

### Requests

server_address, service_name, method_name are all required fields for either request.

Grpcurl tags/attributes supported (mapped GAS -> grpcurl tag):

Headers:
- GRPC_META_server_address [string] => address
- GRPC_META_verbose [boolean] => -v
- GRPC_META_import_path [string] => -import-path
- GRPC_META_service_proto_path [string] => -proto
- GRPC_META_plaintext [boolean] => -plaintext
- GRPC_META_max_time [int] => -max-time
- GRPC_META_connect_timeout [int] => -connect-timeout
- GRPC_META_max_message_size [int] => -max-msg-sz
- GRPC_META_gas_options [string-hash] => None, GAS custom field
- HTTP headers (GRPC_REQ_{header_name}) [map] => -H

Path variables (Ex. path: /service/:service_name/execute/:method_name):
- service_name (in path) [string] => symbol
- method_name (in path) [string] => symbol

Body:
- data (request body) [object] => -d

Grpc metadata is passed in via **headers** prefixed with 'GRPC_META_' (ex. 'GRPC_META_import_path'). Regular request headers to be passed to grpcurl are prefixed with 'GRPC_REQ_' (ex. 'GRPC_REQ_Authorization'). The prefixes are removed during processing, these prefixes are only used to locate GRPC intended headers.

Note: Rails automatically upper cases header text and removes '-' in favor of '_'. So `GRPC_REQ_Authorization-key` and `GRPC_REQ_AUTHORIZATION_KEY` are equivalent. This upper casing will transfer to the grpcurl request. HTTP headers are case insensitive per the HTTP spec so this should not affect HTTP/JSON or grpc operation.

More tags/options support may be added in the future. These are currently all I've needed so far for my development.

### Command Request
The command endpoint will generate a grpcurl command based on the inputs. This command can then be copied and pasted into a command line on a local/different machine with grpcurl. Nothing is executed with this endpoint.

#### Command example request
```
curl --request POST 'localhost:3000/service/com.example.proto.example.FooService/command/ExampleMethod' \
--header 'GRPC_REQ_authorization: auth-token' \
--header 'GRPC_META_import_path: /import/src' \
--header 'GRPC_META_service_proto_path: path/to/proto/service/file/services.proto' \
--header 'GRPC_META_plaintext: false' \
--header 'GRPC_META_verbose: true' \
--header 'GRPC_META_server_address: example.com:443' \
--data-raw '{
 		"foo": 1,
 		"bar": "test"
}
'
```

#### Command example response
A ready to copy and paste response is returned (plaintext response to allow for proper escaping).
```
grpcurl  -import-path /import/src  -proto path/to/proto/service/file/services.proto  -H 'AUTHORIZATION:auth-token'  -v  -d '{"foo":1,"bar":"test"}' example.com:443  com.example.proto.example.FooService/ExampleMethod 
```

### Execute Request
The execute endpoint will generate a grpcurl command based on inputs and **execute the command** using grpcurl inside of the docker container.

#### Execute example request
```
curl --request POST 'localhost:3000/service/com.example.proto.example.FooService/execute/ExampleMethod' \
--header 'GRPC_REQ_authorization: auth-token' \
--header 'GRPC_META_import_path: /import/src' \
--header 'GRPC_META_service_proto_path: path/to/proto/service/file/services.proto' \
--header 'GRPC_META_plaintext: false' \
--header 'GRPC_META_verbose: true' \
--header 'GRPC_META_server_address: example.com:443' \
--data-raw '{
 		"foo": 1,
 		"bar": "test"
}
'
```

#### Execute example response success
The response contains the parsed grpc response (extracted from the full output of grpcurl), the command used (ready to copy and paste), hints for the request (if applicable), and the full output of the execution for additional debugging. By default, this is all returned as plaintext to allow for proper string escaping. See below for how to get GAS to return a JSON response.

Success is indicated via the HTTP status code 200.

```
### Parsed Response ### 

{
    "someObject": {
        "field": "value"
    },
    "foo": "bar"
}


### Command Used ### 

grpcurl  -import-path /import/src  -proto path/to/proto/service/file/services.proto  -H 'AUTHORIZATION:auth-token'  -v  -d '{"foo":1,"bar":"test"}'  example.com:443  com.example.proto.example.FooService/ExampleMethod 

### Hints ###

  - Leading slash on import_path detected. Execution will remove this leading slash automatically but keep it for the output command. No action required.

### Full Response ### 

Resolved method descriptor:
// Some method description
rpc ExampleMethod ( com.example.proto.example.FooService.ExampleMethod ) returns ( com.example.proto.example.FooService.ExampleResponse );

Request metadata to send:
authorization: auth-token

Response headers received:
access-control-expose-headers: X-REQUEST-UUID
content-type: application/grpc+proto
date: Tue, 21 Apr 2020 00:10:04 GMT
server: apache
x-envoy-upstream-service-time: 60
x-request-uuid: afbd18ed-848b-504b-81cb-b8a6bd91b6b8

Response contents:
{
    "someObject": {
        "field": "value"
    },
    "foo": "bar"
}

Response trailers received:
date: Fri, 10 Apr 2020 18:39:38 GMT
Sent 1 request and received 1 response
```

#### Execute example request with JSON response

Notice: The `.json` appended to the URI. This changes the response type from plaintext to JSON.

```
curl --request POST 'localhost:3000/service/com.example.proto.example.FooService/execute/ExampleMethod.json' \
--header 'GRPC_REQ_authorization: auth-token' \
--header 'GRPC_META_import_path: /import/src' \
--header 'GRPC_META_service_proto_path: path/to/proto/service/file/services.proto' \
--header 'GRPC_META_plaintext: false' \
--header 'GRPC_META_verbose: true' \
--header 'GRPC_META_server_address: example.com:443' \
--data-raw '{
 		"foo": 1,
 		"bar": "test"
}
'
```

The response will return only the JSON response body. This can be useful for automation flows and initial FE development.

```
{
    "someObject": {
        "field": "value"
    },
    "foo": "bar"
}
```

#### Execute example failure
In the event of a failure response, the error from the grpcurl request will be captured and returned along with the command used for inspection.

Failure is indicated with the HTTP status code 400.

```
### Error ###

Error invoking method \"com.example.proto.FooService/FakeMethod\": service \"com.example.proto.FooService\" does not include a method named \"FakeMethod\"\n"

### Hints ###

  - Leading slash on import_path detected. Execution will remove this leading slash automatically but keep it for the output command. No action required.
  - Leading slash on service_proto_path detected. grpcurl may fail to locate protos.

### Command Used ###

grpcurl  -import-path /Users/myuser/projects/proto/src/  -proto example/proto/foo/service_api.proto  -H 'AUTHORIZATION:auth-token'  -v  -d '{"foo":"bar"}'  example.com:443  com.example.proto.FooService/FakeMethod
```
### Hints

GAS will attempt to provide hints in the execute command response (plaintext only). The hints are a tool used to help the user understand why a request may have failed or what under-the-hood processing GAS is doing to make grpc requests work that the user should be aware of.

Some examples of hints supported (not exhaustive):
- plaintext flag check - will warn the user that the request may fail against remote servers but should be fine against local servers.
- Invalid JSON check - will warn the user if the input request body was invalid JSON.
- Warn user if GAS is making automatic adjustments in the background the user should know about.

### Autoformatting

GAS can auto-format Date/Time fields into Protobuf format, saving time and effort typing out specific JSON Date/Time format.

Typical Date/Time Protobuf format:

Protobuf Date:
```
{
    "year": 2000,
    "month": 12,
    "day": 31
}
```

Protobuf Timestamp:
```
{
    "seconds":1588532731,
    "nanos":560100000
 }
```

GAS allows the use of standard ISO8601 date format, which it can convert into either Protobuf Date or Timestamp. 

This feature can be enabled with the header `GRPC_META_gas_options: auto_format_dates:true`. The value of the header is a `key:value` string separated by semi-colons.

Usage:

```
curl --request POST 'localhost:3000/service/com.example.proto.example.FooService/command/ExampleMethod.json' \
--header 'GRPC_REQ_authorization: auth-token' \
--header 'GRPC_META_import_path: /import/src' \
--header 'GRPC_META_service_proto_path: path/to/proto/service/file/services.proto' \
--header 'GRPC_META_plaintext: false' \
--header 'GRPC_META_verbose: true' \
--header `GRPC_META_gas_options: auto_format_dates:true` \
--header 'GRPC_META_server_address: example.com:443' \
--data-raw '{
                "timestamp_no_nanos": "2020-05-02T23:39:21Z",
                "timestamp_date": "2020-05-02",
                "timestamp_with_nanos": "2020-05-02T23:39:21.560Z"
}
'
```

Command generated:
```
grpcurl  -import-path '/import/src'  -proto path/to/proto/service/file/services.proto'  -H 'AUTHORIZATION:auth-token'  -v  -d '{"timestamp_no_nanos":{"seconds":1588462761,"nanos":0},"timestamp_date":{"year":2020,"month":5,"day":2},"timestamp_with_nanos":{"seconds":1588462761,"nanos":560000000}}'  example.com:443  com.example.proto.example.FooService/ExampleMethod 
```

Notice in particular the body that was generated from that request (extract below):
```
{
    "timestamp_no_nanos": {
        "seconds": 1588462761,
        "nanos": 0
    },
    "timestamp_date": {
        "year": 2020,
        "month": 5,
        "day": 2
    },
    "timestamp_with_nanos": {
        "seconds": 1588462761,
        "nanos": 560000000
    }
}
```

## Streaming

GAS supports streaming requests. GAS waits until the stream completes so the response will be delayed (this is a limitation of HTTP).

## Compatibility

The development of this tool has been on macOS. It has been built to be OS/environment agnostic. Non-macOS users should expect paths/directory structure and docker-compose setup will differ for other operating systems.

## How is it built
The service uses Rails 6 API and grpcurl inside of a docker container.

The current setup uses Docker and Docker Compose to launch the service locally requiring no environment setup.

## Credit
This project wouldn't be possible if not for the great work of gRPCurl [https://github.com/fullstorydev/grpcurl].
