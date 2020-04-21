#!/bin/bash

echo "GRPC assistant starting..."
docker-compose up -d
docker-compose exec web bundle exec rake db:setup db:migrate
echo "GRPC assistant started."