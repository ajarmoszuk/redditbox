#Build ssh server application
FROM golang:alpine as builder_ssh

COPY app_scripts/ssh/server.go $GOPATH/src/
WORKDIR $GOPATH/src/

RUN apk add git \
    && go get -d -v \
    && go build -o /go/bin/server

#Build less reader
FROM gcc:5.5 as builder_less

WORKDIR /src/

RUN git clone https://github.com/vbwagner/less.git \
    && cd less \
    && sh configure --with-secure \
    && make

#Build redditbox server
FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

RUN apt update -y -qq \
    && apt install xinetd telnetd dialog rtv musl screen ca-certificates wget language-pack-en less -y -qq \
    && locale-gen en_US \
    && locale-gen en_US.UTF-8 \
    && update-locale

COPY app_scripts/telnet /etc/xinetd.d/telnet
RUN echo "" > /etc/issue

COPY app_scripts/motd /app/motd
COPY --from=builder_ssh /go/bin/server /app/server

RUN wget https://github.com/mholt/caddy/releases/download/v0.11.0/caddy_v0.11.0_linux_amd64.tar.gz \
    && tar --extract --file=caddy_v0.11.0_linux_amd64.tar.gz caddy \
    && rm caddy_v0.11.0_linux_amd64.tar.gz \
    && mv caddy /usr/local/bin/

COPY app_scripts/web/ /app/web
COPY app_scripts/Caddyfile /app/Caddyfile
COPY app_scripts/wrapper /app/wrapper
COPY app_scripts/login /app/login
COPY app_scripts/entrypoint /app/entrypoint

COPY --from=builder_less /src/less/less /bin/less
COPY --from=builder_less /src/less/lessecho /bin/lessecho
COPY --from=builder_less /src/less/lesskey /bin/lesskey

RUN chmod -R +x /bin/les* \
    && chmod -R +x /app

EXPOSE 22 23 80 443
CMD /app/entrypoint