FROM alpine:latest
MAINTAINER Vagnerd Fernandes "vagner.rodrigues@gmail.com"

RUN apk update && apk add --no-cache python git \
	&& git clone --depth=1 --branch=master https://github.com/sqlmapproject/sqlmap.git /sqlmap \
	&& adduser -D sqlmap \
	&& mkdir /data \
	&& chown -R sqlmap /sqlmap /data \
	&& rm -rf /var/cache/apk/*i \
	&& python /sqlmap/sqlmap.py --update

USER sqlmap

VOLUME /data

WORKDIR /sqlmap
