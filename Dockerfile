FROM squidfunk/mkdocs-material:latest
ADD . /docs
WORKDIR /docs
RUN mkdocs build


FROM nginx:alpine
WORKDIR /
COPY --from=0 /docs/site /var/www
ADD .docker/nginx.conf /etc/nginx/nginx.conf
