#!/bin/bash
sh ./stop_grpc_assistant.sh
echo "GRPC assistant server updating..."
git pull
docker-compose build --no-cache
echo "GRPC assistant server updated."