FROM ruby:3.0.4-alpine3.15 as base
RUN apk add terraform
ADD Gemfile* ./
RUN gem install bundler
RUN bundle install

FROM base as app
WORKDIR /events
ADD events ./events
ADD tf ./tf

FROM app as dev
ENV POLYN_ENV='development'

FROM app as prod
ENV POLYN_ENV='production'