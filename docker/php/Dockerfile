FROM php:7.4-fpm-alpine3.16

# Instalar dependencias del sistema
RUN apk add --no-cache \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    curl \
    oniguruma-dev \
    libxml2-dev \
    icu-dev \
    postgresql-dev \
    linux-headers \
    $PHPIZE_DEPS

# Instalar extensiones PHP necesarias para Drupal
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
        gd \
        pdo \
        pdo_mysql \
        mysqli \
        opcache \
        zip \
        mbstring \
        xml \
        intl \
        bcmath \
        exif \
        pcntl

# Instalar Redis (opcional)
RUN pecl install redis && docker-php-ext-enable redis

# Instalar APCu para caché de usuario
RUN pecl install apcu && docker-php-ext-enable apcu

# Instalar Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Configurar usuario www-data usando método Alpine (deluser + adduser)
RUN deluser www-data && \
    addgroup -g 1000 www-data && \
    adduser -u 1000 -G www-data -h /var/www -s /sbin/nologin -D www-data

# Crear directorios necesarios
RUN mkdir -p /var/www/html/sites/default/files \
    && mkdir -p /var/www/private \
    && chown -R www-data:www-data /var/www

# Copiar configuración PHP
COPY php.ini /usr/local/etc/php/php.ini
COPY opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Script de entrada personalizado
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html

USER www-data

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]