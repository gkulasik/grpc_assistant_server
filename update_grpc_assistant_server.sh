#!/bin/bash
sh ./stop_grpc_assistant_server.sh
echo "GRPC assistant server updating..."
git pull
docker pull gkulasik/grpc-assistant-server:1.0.0
echo "GRPC assistant server updated."