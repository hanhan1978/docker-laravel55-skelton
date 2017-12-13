FROM node:9.2

COPY laravel /var/laravel

WORKDIR /var/laravel

RUN npm install \
  && npm rebuild node-sass \
  && npm run production

RUN rm -rf ./node_modules

FROM php:7.2-fpm-alpine

# install libraries
RUN apk upgrade --update \
    && apk add \
       git \
       zlib-dev \
       nginx \
    && docker-php-ext-install pdo_mysql zip \
    && mkdir /run/nginx

# install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
  && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
  && php -r "unlink('composer-setup.php');"

ENV COMPOSER_ALLOW_SUPERUSER 1

# setting up apps
COPY ./conf/nginx.conf /etc/nginx/nginx.conf
COPY --from=0 /var/laravel /var/www/laravel
WORKDIR /var/www/laravel

# install php libraries && compile laravel mix
RUN composer install --no-dev

RUN find ./vendor -iname tests -type d | xargs rm -rf \
    && find ./vendor -iname tests -type d | xargs rm -rf

FROM nginx:1.13-alpine

COPY ./conf/nginx.conf /etc/nginx/nginx.conf
COPY --from=1 /var/www/laravel /var/www/laravel

COPY ./run.sh /usr/local/bin/run.sh

COPY --from=1 /usr/local/bin/php /usr/local/bin/php
COPY --from=1 /usr/local/sbin/php-fpm /usr/local/sbin/php-fpm
COPY --from=1 /lib/ld-musl-x86_64.so.1 /lib/ld-musl-x86_64.so.1
COPY --from=1 /usr/lib/libedit.so.0 /usr/lib/libedit.so.0
COPY --from=1 /lib/libz.so.1 /lib/libz.so.1
COPY --from=1 /usr/lib/libxml2.so.2 /usr/lib/libxml2.so.2
COPY --from=1 /lib/libssl.so.43 /lib/libssl.so.43
COPY --from=1 /lib/libcrypto.so.41 /lib/libcrypto.so.41
COPY --from=1 /usr/lib/libcurl.so.4 /usr/lib/libcurl.so.4
COPY --from=1 /lib/ld-musl-x86_64.so.1 /lib/ld-musl-x86_64.so.1
COPY --from=1 /usr/lib/libncursesw.so.6 /usr/lib/libncursesw.so.6
COPY --from=1 /usr/lib/libssh2.so.1 /usr/lib/libssh2.so.1


COPY --from=1 /usr/local/etc /usr/local/etc
COPY --from=1 /usr/local/lib/php/extensions /usr/local/lib/php/extensions

WORKDIR /var/www/laravel

RUN chown nginx:nginx storage/logs \
    && sed -i 's/www-data/nginx/g' /usr/local/etc/php-fpm.d/www.conf \
    && chown -R nginx:nginx storage/framework \
    && cp .env.example .env \
    && php artisan key:generate \
    && ln -s /var/www/laravel/public /usr/share/nginx/html

CMD ["run.sh"]
