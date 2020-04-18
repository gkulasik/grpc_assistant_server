# Start with a Ruby base
FROM ruby:2.5.5

# Install/update dependencies
#RUN apt-get update -qq && apt-get install -y build-essential nano software-properties-common postgresql postgresql-contrib tzdata
#RUN apt-get install -y libpq-dev libxml2-dev libxslt1-dev libqt4-dev xvfb nodejs
RUN gem install bundler -v '2.0.1'

RUN mkdir /app
WORKDIR /app

ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install

ADD . /app
