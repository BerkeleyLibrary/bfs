FROM ruby:2.5-alpine3.12 AS base
RUN apk --no-cache --update upgrade && apk add --no-cache build-base\
&&  apk --no-cache add \
        bash \
        ruby-dev \
        libc6-compat \
        git \
        libxml2-dev \
        libxslt-dev \
        libffi-dev \
        tzdata \
        xz-libs \
        yarn \
        shared-mime-info \ 
&&  rm -rf /var/cache/apk/*


WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle install
COPY ./Gemfile /app
COPY ./src/* /app
