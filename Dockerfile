FROM debian:buster
ARG MDBOOK_VERSION=v0.3.0
RUN DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt -y install wget && \
  rm -rf /root/* /tmp/* /var/tmp/* /var/log/* /var/lib/apt/lists/* && \
  wget -qO - https://github.com/azerupi/mdBook/releases/download/${MDBOOK_VERSION}/mdBook-${MDBOOK_VERSION}-x86_64-unknown-linux-gnu.tar.gz | tar -C /usr/bin -xzf -
ADD src /tmp/src
WORKDIR /tmp
RUN mdbook build


FROM smartentry/alpine:3.4-0.3.13
MAINTAINER Yifan Gao <docker@yfgao.com>
WORKDIR /
COPY --from=0 /tmp/book /var/www
ADD .docker $ASSETS_DIR
RUN smartentry.sh build
