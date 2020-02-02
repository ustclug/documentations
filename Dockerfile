FROM squidfunk/mkdocs-material:latest
ADD . /docs
WORKDIR /docs
RUN mkdocs build


FROM smartentry/alpine:3.4-0.3.13
MAINTAINER Yifan Gao <docker@yfgao.com>
WORKDIR /
COPY --from=0 /docs/site /var/www
ADD .docker $ASSETS_DIR
RUN smartentry.sh build
