FROM alpine:3.5
ARG MDBOOK_VERSION=0.0.21
RUN apk add --no-cache curl caddy
RUN curl -sSL https://github.com/azerupi/mdBook/releases/download/${MDBOOK_VERSION}/mdBook-${MDBOOK_VERSION}-x86_64-unknown-linux-musl.tar.gz | tar -C /usr/bin -xzf -
ADD src /tmp/src
WORKDIR /tmp
RUN mdbook build
RUN mv book/* /var/www
RUN apk del --purge curl
RUN rm -rf /tmp/*
WORKDIR /var/www
CMD ["caddy", "-host", ":80"]
