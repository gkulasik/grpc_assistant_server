# Start with a Ruby base
FROM ruby:2.5.5

# Install/update dependencies
RUN apt-get update -qq && apt-get install -y build-essential nano software-properties-common postgresql postgresql-contrib
RUN apt-get install -y libpq-dev libxml2-dev libxslt1-dev libqt4-dev xvfb nodejs
RUN gem install bundler

# Clone repo
RUN mkdir /grpc_server_assistant
RUN git clone https://github.com/gkulasik/grpc_server_assistant.git /grpc_server_assistant

# Setup gems
WORKDIR /grpc_server_assistant
RUN bundle install
