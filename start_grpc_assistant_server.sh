#!/bin/bash

echo "GRPC assistant server starting..."
docker-compose up -d
# Sleep to allow Rails app to start up fully
sleep 15
docker-compose exec web bundle exec rake db:setup db:migrate
echo "GRPC assistant server started."