# GRPC Assistant Server (GAS)

## What it is:
Dockerized HTTP/JSON proxy server for local GRPC development leveraging grpcurl [https://github.com/fullstorydev/grpcurl].

## What it can do
- Generate valid, ready to copy and paste, grpcurl commands from a request using JSON.
- Execute and parse grpc commands within a docker container and return a formatted response.

##  What are the benefits?
- Free choice of UI (choose your http client such as Postman, Paw, etc.) and all the features they support such as saving requests, variables, and testing.
- Minimal setup required due to being fully dockerized (server and grpcurl).
- Craft GRPC request bodies and view responses in JSON format.
- Leverage a trusted base with grpcurl. Easily works with grpc servers, no tls or server compatibility issues like other grpc tools may have.
- Requests are easily portable and transferable due to the text based nature of grpcurl or equivalent curl.
- No changes are required to existing proto files or servers like some other grpc tools.

## How is it built
The service uses Rails 6 API and grpcurl inside of a docker container. A second container containing a database is generated but currently is unused.

The current setup uses Docker and Docker Compose to launch the service locally requiring no environment setup.

Prebuilt containers at Docker Hub (Still requires that the git repo is pulled): https://hub.docker.com/repository/docker/gkulasik/grpc_assistant_server

##  Setup

Download the code via git clone: `git clone https://github.com/gkulasik/grpc_assistant_server.git`

This will create a new directory called grpc_assistant_server with all the necessary files. 

### Start the service

`./start_grpc_assistant_server.sh`

Will start the Rails server and run migrations against the internal Sqlite3 DB. Access from localhost:3000 by default. On first run the docker containers will be pulled.

### Stop the service

`./stop_grpc_assistant_server.sh`

Will shutdown and remove the server and DB containers.

### Update the service

`./update_grpc_assistant_server.sh`

Will stop the service, git pull the latest changes, and repull the docker container.

### Set the protos source
The service and grpcurl need to know where the proto files are. The docker container **cannot** see files outside of its local directory. There are two options to provide the service with access to local proto files. Getting the protos config right is the most important part to ensure the service works correctly.

#### Option 1
Copy proto files/directories into the directory created by git clone. Docker and the service will have access to its directory and any child directories. grpcurl commands will only work within the service directory from the command line due to the proto file paths being part of the command.

#### Option 2 (Preferred)
Provide access to directories outside of the service directory via docker-compose volumes. This is already partially configured in the docker-compose.yml file.

```
docker-compose.yml
    volumes:
      - ./:/app
      - /Users:/app/Users
```

With the default config (configured for macOS) the /Users directory will be passed to the docker container, passing access to nearly the whole system including the protos. More granularity is possible for those who choose to tinker with the volumes and related request body options.import_path. 

grpcurl commands will work from the top level `/` directory on macOS using the default config.

Example of how to set up a request's options.import_path with the default docker-compose.yml volumes. Assuming the protos are located in foouser's projects directory.

```
Request body sample:
"options": {
        	...
 		"import_path": "Users/foouser/projects/protos/src/",
 		...
 	},
	...
```
 	
This would mean that the protos directory structure starts in the /src directory.  

Ideally, volumes and import_path work so that the command returned in a response will work to be copied and pasted without any edits required to the command. 

## Configuration

The primary config is handled in the **docker-compose.yml** file.

- The port that the server runs at can be adjusted if you are using port 3000 for other development or services. If changing the port be sure to adjust both the command and ports config.
- The volumes section needs to be adjusted to allow for the protos to be discovered via Docker volumes. See above in 'Set the protos source' on how to set this up.
- All other applicable docker-compose changes are available but shouldn't be necessary for general usage.

### Building the container locally

The docker containers can be built rather then pulled after git pull by editing the docker-compose.yml file.

Remove `image: gkulasik/grpc_assistant_server...` under `web` and replace with:

```
 build:
       context: .
       dockerfile: Dockerfile
```

Avoid using the update script as it will attempt to pull the container.

## Usage
There are two primary API endpoints the service provides, `command` and `execute`.

### General

server_address, service_name, method_name are all required fields for either request.

Grpcurl tags/attributes supported (mapped GAS -> grpcurl tag):
- options.verbose [boolean] => -v
- options.import_path [string] => -import-path
- options.service_proto_path [string] => -proto
- options.plaintext [boolean] => -plaintext
- options.max_time [int] => -max-time
- options.connect_timeout [int] => -connect-timeout
- options.max_message_size [int] => -max-msg-sz
- server_address [string] => address
- service_name [string] => symbol
- method_name [string] => symbol
- data [object] => -d
- HTTP headers [map] => -H

To pass in headers (grpcurl -H tag) regular HTTP headers may be used. The service will look for 'GRPC' intended headers which are any HTTP headers prefixed with 'HTTP_GRPC_{your header name}'. The 'HTTP_GRPC_' prefix will be removed during processing.

Note: In Postman HTTP_ is already prefixed to headers automatically and Postman does its own automatic header adjustments. Example header key with Postman could look like this: 'GRPC_Authorization' or like 'grpc-Authorization' (both will be handled correctly).

More tags/options support may be added in the future. These are currently all I've needed so far for my development.

### Command
The command endpoint will generate a grpcurl command based on the inputs. This command can then be copy and pasted into a command line on a local/different machine with grpcurl. Nothing is executed with this endpoint.

#### Command example request
```
POST localhost:3000/service/command
Header:  grpc-Authorization: auth-token
{
	"options": {
		"verbose": true,
		"import_path": "import/src",
		"service_proto_path": "path/to/proto/service/file/services.proto",
		"plaintext": false
	},
	"server_address": "example.com:443",
	"service_name": "com.example.proto.example.FooService",
	"method_name": "ExampleMethod",
	"data": {
		"foo": 1,
		"bar": "test"
	}
}
```
Equivalent curl:
```
curl --location --request POST 'localhost:3000/service/command' \
 --header 'grpc-Authorization: auth-token' \
 --header 'Content-Type: application/json' \
 --data-raw '{
 	"options": {
 		"verbose": true,
 		"import_path": "import/src",
 		"service_proto_path": "path/to/proto/service/file/services.proto",
 		"plaintext": false
 	},
 	"server_address": "example.com:443",
 	"service_name": "com.example.proto.example.FooService",
 	"method_name": "ExampleMethod",
 	"data": {
 		"foo": 1,
 		"bar": "test"
 	}
 }'
``` 


#### Command example response
A ready to copy and paste response is returned (plain text response to allow for proper escaping).
```
grpcurl  -import-path import/src  -proto path/to/proto/service/file/services.proto  -H 'AUTHORIZATION:auth-token'  -v  -d '{"foo":1,"bar":"test"}' example.com:443  com.example.proto.example.FooService/ExampleMethod 
```


### Execute
The execute endpoint will generate a grpcurl command based on inputs and **execute the command** using grpcurl inside of the docker container.

#### Execute example request
```
POST localhost:3000/service/execute
Header: grpc-Authorization: auth-token
{
	"options": {
		"verbose": true,
		"import_path": "import/src",
		"service_proto_path": "path/to/proto/service/file/services.proto",
		"plaintext": false
	},
	"server_address": "example.com:443",
	"service_name": "com.example.proto.example.FooService",
	"method_name": "ExampleMethod",
	"data": {
		"foo": 1,
		"bar": "test"
	}
}
```

Equivalent curl:
```
curl --location --request POST 'localhost:3000/service/execute' \
 --header 'grpc-Authorization: auth-token' \
 --header 'Content-Type: application/json' \
 --data-raw '{
 	"options": {
 		"verbose": true,
 		"import_path": "import/src",
 		"service_proto_path": "path/to/proto/service/file/services.proto",
 		"plaintext": false
 	},
 	"server_address": "example.com:443",
 	"service_name": "com.example.proto.example.FooService",
 	"method_name": "ExampleMethod",
 	"data": {
 		"foo": 1,
 		"bar": "test"
 	}
 }'
```

#### Execute example response success
Response contains the parsed response (extracted from the full output below), the command used (ready to copy and paste), and the full output of the command for additional debugging. This is all returned as plain text to allow for proper string escaping.

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

grpcurl  -import-path import/src  -proto path/to/proto/service/file/services.proto  -H 'AUTHORIZATION:auth-token'  -v  -d '{"foo":1,"bar":"test"}'  example.com:443  com.example.proto.example.FooService/ExampleMethod 

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

#### Execute example failure
In the event of a failure response, the error from the grpcurl request will be captured and returned along with the command used for inspection.

Failure is indicated with the HTTP status code 400.

```
### Error ###

Error invoking method \"com.example.proto.FooService/FakeMethod\": service \"com.example.proto.FooService\" does not include a method named \"FakeMethod\"\n"

### Command Used ###

grpcurl  -import-path Users/myuser/projects/proto/src/  -proto example/proto/foo/service_api.proto  -H 'AUTHORIZATION:auth-token'  -v  -d '{"foo":"bar"}'  example.com:443  com.example.proto.FooService/FakeMethod
```

## Credit
This project wouldn't be possible if not for the great work of grpcurl [https://github.com/fullstorydev/grpcurl].
