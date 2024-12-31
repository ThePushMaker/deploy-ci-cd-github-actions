# Usamos una imagen base oficial de PHP 8.2 con FPM y Alpine
FROM php:8.2-fpm-alpine

# Actualizamos el gestor de paquetes e instalamos dependencias necesarias
RUN apk add --update --no-cache \
    curl \
    bash \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    libxpm-dev \
    freetype-dev \
    zip \
    libzip-dev \
    oniguruma-dev \
    autoconf \
    gcc \
    g++ \
    make \
    icu-dev \
    libxml2-dev \
    curl-dev \
    git \
    zlib-dev && \   # Necesario para Swoole
    docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
        --with-xpm && \
    docker-php-ext-install -j$(nproc) gd mbstring xml curl zip bcmath soap intl pcntl && \
    pecl install swoole && \
    docker-php-ext-enable swoole && \
    apk del autoconf gcc g++ make

# Instalamos Composer
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin --filename=composer

# Copiamos Roadrunner desde su imagen oficial
COPY --from=spiralscout/roadrunner:2.4.2 /usr/bin/rr /usr/bin/rr

# Configuramos el directorio de trabajo
WORKDIR /app

# Copiamos los archivos del proyecto
COPY . .

# Creamos el archivo de base de datos SQLite y ajustamos permisos
RUN mkdir -p /app/database && touch /app/database/database.sql
