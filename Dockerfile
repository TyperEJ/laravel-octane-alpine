FROM php:8.1.8-cli-alpine3.15

###########################################
# Composer
###########################################

RUN \
       curl -sfL https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer && \
       chmod +x /usr/bin/composer                                                                     && \
       composer self-update --clean-backups 2.3.10

###########################################
# Swoole
###########################################

RUN \
    apk update && \
    apk add --no-cache libstdc++ libpq && \
    apk add --no-cache --virtual .build-deps $PHPIZE_DEPS curl-dev postgresql-dev openssl-dev pcre-dev pcre2-dev zlib-dev && \
    docker-php-ext-install sockets pcntl && \
    docker-php-source extract && \
    mkdir /usr/src/php/ext/swoole && \
    curl -sfL https://github.com/swoole/swoole-src/archive/v5.0.0.tar.gz -o swoole.tar.gz && \
    tar xfz swoole.tar.gz --strip-components=1 -C /usr/src/php/ext/swoole && \
    docker-php-ext-configure swoole \
        --enable-mysqlnd      \
        --enable-swoole-pgsql \
        --enable-openssl      \
        --enable-sockets --enable-swoole-curl && \
    docker-php-ext-install -j$(nproc) swoole && \
    rm -f swoole.tar.gz $HOME/.composer/*-old.phar && \
    docker-php-source delete && \
    apk del .build-deps

###########################################
# OPcache
###########################################

RUN docker-php-ext-install opcache;

###########################################
# Redis
###########################################

RUN apk add --no-cache --virtual .build-deps pcre-dev $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis.so \
    && apk del .build-deps

###########################################
# Laravel require extensions
###########################################

RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS oniguruma-dev libxml2-dev && \
    docker-php-ext-install pdo pdo_mysql mbstring ctype bcmath xml && \
    apk del .build-deps

WORKDIR "/var/www/html"

EXPOSE 8000

CMD ["php", "artisan", "octane:start", "--host=0.0.0.0"]
