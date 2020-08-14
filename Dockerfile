FROM ruby:2.6.3

# Install/update dependencies
RUN apt-get update && \
    apt-get install -y git make musl-dev libsqlite3-dev curl build-essential file locales bash && \
    rm -rf /var/lib/apt/lists/*

# Install Homebrew for easier installations
RUN localedef -i en_US -f UTF-8 en_US.UTF-8

RUN useradd -m -s /bin/bash linuxbrew && \
    echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers

USER linuxbrew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"


USER root
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"

# Insall grpcurl
RUN brew install grpcurl

# Setup ruby/app env
RUN gem install bundler -v '2.0.1'
RUN mkdir /app
WORKDIR /app

ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install

ADD . /app
