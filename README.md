# GRPC Assistant Server (GAS)

## About
This project was born out of a need to be more efficient in working with GRPC. Though very powerful and full of benefits, few tools work well for development and testing against GRPC servers. 

Various GRPC tools require special syntax, lacked features, and sometimes don't work as expected. These tools are extremely appreciated and I know take personal time to maintain but coming from tools like Postman it makes it difficult to keep a similar development efficiency.

One tool I consistently use is grpcurl [https://github.com/fullstorydev/grpcurl] and find it to be extremely usable and  reliable. Though, on account of it being a command-line utility, it suffers the same issues as regular curl [https://curl.haxx.se/] such as the tedious typing of JSON request bodies.

We already have great development tools for HTTP requests like curl and Postman [https://www.postman.com/] so I thought about why not use them to create and format our GRPC requests.

This tool is intended to be used with Postman due to its great UI and support for variables, environments, and programmability.

### Build
The service uses Rails 6 API and grpcurl under the hood. Rails was chosen due to its quick development time and ability to expand if more functionality is desired.

The current setup uses Docker and Docker Compose to launch the service locally requiring no environment setup.

##  Setup

Download the code via git clone: `git clone https://github.com/gkulasik/grpc_assistant_server.git`

This will create a new directory called grpc_assistant_server with all the necessary files. 

### Start the service

`./start_grpc_assistant_server.sh`

Will start the Rails server, Postgres DB, and run migrations. Access from localhost:3000 by default.

### Stop the service

`./stop_grpc_assistant_server.sh`

Will shutdown and remove the server and DB containers.

### Update the service

`./update_grpc_assistant_server.sh`

Will stop the service, git pull the latest changes, and rebuild the docker container.

### Set the protos source
The service and grpcurl need to know where the proto files are. The docker container **cannot** see files outside of its local directory. There are two options to the service with access to local proto files. Getting the protos config right is the most difficult part to ensure the command and execute endpoints work correctly.

#### Option 1
Copy proto files/directories into the directory created by git clone. Docker and the service will have access to its directory and any child directories.

#### Option 2 (Preferred)
Provide access to directories outside of the service directory via docker-compose volumes. This is already partially configured in the docker-compose.yml file.

```
docker-compose.yml
    volumes:
      - ./:/app
      - /Users:/app/Users
```

With the default config (configured for macOS) the /Users directory will be passed to the docker container, passing access to nearly the whole system and should provide access to the protos. While not ideal, this solution works, more granularity is possible for those who choose to tinker with the volumes and related request body options.import_path.

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

## Config

The primary config is handled in the **docker-compose.yml** file.

- The port that the server runs at can be adjusted if you are using port 3000 for other development or services. If changing the port be sure to adjust both the command and ports config.
- The volumes section needs to be adjusted to allow for the protos to be discovered via Docker volumes. See above in 'Set the protos source' on how to set this up.
- All other applicable docker-compose changes are available but shouldn't be necessary for general usage.

## Usage
There are two primary API endpoints the service provides, `command` and `execute`.

### General

server_address, service_name, method_name are all required fields in either request.

Grpcurl tags/attributes supported (mapped GAS -> grpcurl tag):
- options.verbose [boolean] => -v
- options.import_path [string] => -import-path
- options.service_proto_path [string] => -proto
- options.insecure [boolean] => -plaintext
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
A ready to copy and paste response is returned (plain text response to allow for proper escaping).
```
grpcurl  -import-path import/src  -proto path/to/proto/service/file/services.proto  -H 'AUTHORIZATION:auth-token'  -v  -d '{"foo":1,"bar":"test"}' example.com:443  com.example.proto.example.FooService/ExampleMethod 
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
Response contains the parsed response (from the full output at the bottom), the command used (ready to copy and paste), and the full output of the command for additional debugging. This is all returned as plain text to allow for proper string escaping.

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
