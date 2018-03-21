FROM centos:7
ARG MDBOOK_VERSION=v0.1.5
RUN curl -sSL https://github.com/azerupi/mdBook/releases/download/${MDBOOK_VERSION}/mdBook-${MDBOOK_VERSION}-x86_64-unknown-linux-gnu.tar.gz | tar -C /usr/bin -xzf -
ADD src /tmp/src
WORKDIR /tmp
RUN mdbook build


FROM smartentry/alpine:3.4-0.3.13
MAINTAINER Yifan Gao <docker@yfgao.com>
WORKDIR /
COPY --from=0 /tmp/book /var/www
ADD .docker $ASSETS_DIR
RUN smartentry.sh build
