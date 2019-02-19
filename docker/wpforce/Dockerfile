FROM alpine:latest
MAINTAINER Vagnerd Fernandes "vagner.rodrigues@gmail.com"

RUN apk update && apk add --no-cache python git \
	&& git clone --depth=1 --branch=master https://github.com/n00py/WPForce.git /wpforce

WORKDIR /wpforce
