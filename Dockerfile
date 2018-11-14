#Build ssh server application
FROM golang:alpine as builder_ssh

COPY app_scripts/ssh/server.go $GOPATH/src/
WORKDIR $GOPATH/src/

RUN apk add git
RUN go get -d -v
RUN go build -o /go/bin/server

#Build server
FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

RUN apt update -y -qq && apt install xinetd telnetd dialog rtv musl screen ca-certificates wget language-pack-en less -y -qq
RUN locale-gen en_US
RUN locale-gen en_US.UTF-8
RUN update-locale

COPY app_scripts/telnet /etc/xinetd.d/telnet
RUN echo "" > /etc/issue

COPY app_scripts/motd /app/motd
COPY --from=builder_ssh /go/bin/server /app/server

RUN wget https://github.com/mholt/caddy/releases/download/v0.11.0/caddy_v0.11.0_linux_amd64.tar.gz
RUN tar --extract --file=caddy_v0.11.0_linux_amd64.tar.gz caddy
RUN rm caddy_v0.11.0_linux_amd64.tar.gz
RUN mv caddy /usr/local/bin/
COPY app_scripts/web/ /app/web

COPY app_scripts/Caddyfile /app/Caddyfile
COPY app_scripts/wrapper /app/wrapper
COPY app_scripts/login /app/login
COPY app_scripts/entrypoint /app/entrypoint

RUN chmod -R +x /app

EXPOSE 22 23 80 443
CMD /app/entrypoint
