
FROM php:7.2-fpm-alpine

MAINTAINER hanhan1978 <ryo.tomidokoro@gmail.com>

# install libraries
RUN apk upgrade --update \
    && apk add \
       git \
       zlib-dev \
       nginx \
       nodejs \
       nodejs-npm \
    && docker-php-ext-install pdo_mysql zip \
    && mkdir /run/nginx

# install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
  && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
  && php -r "unlink('composer-setup.php');"

ENV COMPOSER_ALLOW_SUPERUSER 1

# setting up apps
COPY ./conf/nginx.conf /etc/nginx/nginx.conf
COPY laravel /var/www/laravel
WORKDIR /var/www/laravel

# install php libraries && compile laravel mix
RUN composer install --no-dev \
    && npm install \
    && npm rebuild node-sass \
    && npm run production

RUN chown www-data:www-data storage/logs \
    && chown -R www-data:www-data storage/framework \
    && cp .env.example .env \
    && php artisan key:generate \
    && mkdir -p  /usr/share/nginx \
    && ln -s /var/www/laravel/public /usr/share/nginx/html

COPY ./run.sh /usr/local/bin/run.sh

CMD ["run.sh"]
