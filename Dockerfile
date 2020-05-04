FROM ruby:2.6.3

# Install/update dependencies
RUN apt-get update && apt-get install -y golang-go git make musl-dev libsqlite3-dev

# Configure Go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

# Install grpcurl
RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin
RUN go get github.com/fullstorydev/grpcurl
RUN go install github.com/fullstorydev/grpcurl/cmd/grpcurl

# Setup ruby/app env
RUN gem install bundler -v '2.0.1'
RUN mkdir /app
WORKDIR /app

ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install

ADD . /app
