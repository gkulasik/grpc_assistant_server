#!/bin/bash

docker-compose up -d
docker-compose exec web bundle exec rake db:setup db:migrate