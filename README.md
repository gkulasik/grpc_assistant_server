# GRPC Server Assistant

## About
This project was born out of a need to be more efficient working with GRPC. Though very powerful and full of benefits, there are few tools that work well for development and testing against GRPC servers. 

Various GRPC tools require special syntax, lacked features, and sometimes don't work as expected. These tools are extremely appreciated and I know take extra time to maintainbut coming from tools like Postman it makes it difficult to keep a similar development efficiency.

One tool I consistently use is grpcrl [https://github.com/fullstorydev/grpcurl] and find it to be extremely usable and  reliable. Though, on account of it being a command line utility it suffers the same issues as regular curl [https://curl.haxx.se/] such as the tediousness of typing out JSON structure by hand for a request body.

We already have great development tools for HTTP requests like curl and Postman [https://www.postman.com/] so I thought about why not use them to create and format our GRPC requests.

This tool is best used with Postman due to its great UI and support for variables, environments, and programmability.

### Build
The service uses Rails 6 API and grpcurl under the hood. Rails was chosen due to its quick development time and ability to expand if more functionality is desired.

The current setup uses Docker and Docker Compose to launch the service locally requiring no environment setup.

##  Setup

Download the code via git clone: `git clone https://github.com/gkulasik/grpc_server_assistant.git`

This will create a new directory called grpc_server_assistant with all the necessary files. 

### Start the service

`./start_grpc_assistant.sh`

Will start the Rails server, postgres DB, and run migrations. Access from localhost:3000 by default.

### Stop  the  service

`./stop_grpc_assistant.sh`

Will shutdown and remove the server and DB containers.

### Set the protos source
It is important for the service and grpcurl to know where the proto files are. The docker container **cannot** see files outside of its local directory. There are two options to the service with access to local proto files. Getting the protos config right is the most difficult part to ensure the command and execute endpoints work correctly.

#### Option 1
Copy proto files/directories into the directory created by git clone. Docker and the service will have access to its directory and any child directories.

#### Option 2 (Preferred)
Provide access to directories outside of the service directory via docker compose volumes. This is already partially configured in the docker-compose.yml file.

```
docker-compose.yml
    volumes:
      - ./:/app
      - /Users:/app/Users
```

With the default config (configured for MacOS) the /Users directory will be passed to the docker container, passing access to nearly the whole system and should provided access to the protos. While not ideal, this solution works, more granularity is possible for those who choose to tinker with the volumes and related request body options.import_path.

Example on how to setup a request's options.import_path with the default docker-compose.yml volumes. Assuming the protos are located in foouser's projects directory.

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

## Config

The primary config is handled in the **docker-compose.yml** file.

- The port that the server runs at can be adjusted if you are using port 3000 for other development or services. If changing the port be sure to adjust both the command and ports config.
- The volumes section needs to be adjusted to allow for the protos to be discovered via Docker volumes. See above in 'Set the protos source' on how to set this up.
- All other applicable docker-compose changes are available but shouldn't be necessary for general usage.

## Usage
There are two primary API endpoints the service provides, `command` and `execute`.

### General

server_address, service_name, method_name are all required fields in either request.

Grpcurl tags/attributes supported (mapped GRPC Assistant -> grpcurl tag):
- options.verbose [boolean] => -v
- options.import_path [string] => -import-path
- options.service_proto_path [string] => -proto
- options.insecure [boolean] => -plaintext
- server_address [string] => address
- service_name [string] => symbol
- method_name [string] => symbol
- data [Object] => -d
- HTTP headers [Map] => -H

To pass in headers (grpcurl -H tag) regular HTTP headers may be used. The service will look for 'GRPC' intended headers which are any HTTP headers prefixed with 'HTTP_GRPC_{your header name}'. The 'HTTP_GRPC_' prefix will be removed during processing.

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
		"insecure": false
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
 		"insecure": false
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
A ready to copy and paste response (value of the 'command' field) is returned.
```
{
     "command": "grpcurl  -import-path import/src  -proto path/to/proto/service/file/services.proto  -H 'AUTHORIZATION:auth-token'  -v  -d {\"foo\":1,\"bar\":\"test\"}  example.com:443  com.example.proto.example.FooService/ExampleMethod "
}
```


### Execute
The execute endpoint will generate a grpcurl command based on inputs and **execute the command** with grpcurl inside of the docker container.

#### Execute example request
```
POST localhost:3000/service/execute
Header: grpc-Authorization: auth-token
{
	"options": {
		"verbose": true,
		"import_path": "import/src",
		"service_proto_path": "path/to/proto/service/file/services.proto",
		"insecure": false
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
 		"insecure": false
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
Response contains a success indicator, the actual GRPC response (JSON format), the command used for grpcurl, and the full output from grpcurl for debugging.
```
{
    "success": true,
    "response": {
        "someObject": {
            "field": "value"
        },
        "foo": "bar"
    },
    "command": "grpcurl  -import-path import/src  -proto path/to/proto/service/file/services.proto  -H 'AUTHORIZATION:auth-token'  -v  -d {\"foo\":1,\"bar\":\"test\"}  example.com:443  com.example.proto.example.FooService/ExampleMethod ",
    "full_output": "\nResolved method descriptor:\n// some test method ( com.example.proto.example.FooService.ExampleMethod ) returns ( com.example.proto.example.FooService.ExampleResponse );\n\nRequest metadata to send:\nauthorization: auth-token\n\nResponse headers received:\naccess-control-expose-headers: X-REQUEST-UUID\ndate: Mon, 20 Apr 2020 10:11:36 GMT\nserver: apache\nx-envoy-upstream-service-time: 55\nx-request-uuid: 773a276d-8c8e-5158-abcd-ac616a3e921a\n\nResponse contents:\n{\n  \"someObject\": {\n    \"field\": \"value\"\n  }, \"foo\":\"bar\"\n}\n\nResponse trailers received:\ndate: Fri, 10 Apr 2020 19:12:43 GMT\nSent 1 request and received 1 response\n"
}
```

#### Execute example failure
In the event of a failure response the error from the grpcurl request will be captured and returned along with the command used for inspection.
```
{
    "success": false,
    "errors": "Error invoking method \"com.example.proto.FooService/FakeMethod\": service \"com.example.proto.FooService\" does not include a method named \"FakeMethod\"\n",
    "command": "grpcurl  -import-path Users/myuser/projects/proto/src/  -proto example/proto/foo/service_api.proto  -H 'AUTHORIZATION:auth-token'  -v  -d {\"foo\":\"bar\"}  example.com:443  com.example.proto.FooService/FakeMethod "
}
```

## Credit
This project wouldn't be possible if not for the great work of grpcurl [https://github.com/fullstorydev/grpcurl].
