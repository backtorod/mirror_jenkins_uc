FROM nginx

ADD default.conf /etc/nginx/conf.d/default.conf

RUN usermod -u 99 nginx \
  && groupmod -g 99 nginx

USER 99
