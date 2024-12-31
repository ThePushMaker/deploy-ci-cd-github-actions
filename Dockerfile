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
    curl-dev && \
    docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
        --with-xpm && \
    docker-php-ext-install -j$(nproc) gd && \
    docker-php-ext-install -j$(nproc) mbstring xml curl zip bcmath soap intl pcntl && \
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
RUN mkdir -p /app/database && touch /app/database/database.sqlite
RUN chmod 777 /app/database/database.sqlite

# Eliminamos archivos previos
RUN rm -rf /app/vendor
RUN rm -rf /app/composer.lock

# Instalamos dependencias de Composer
RUN composer install
RUN composer require laravel/octane spiral/roadrunner

# Configuramos el entorno
COPY .env.example .env

# Creamos directorios necesarios
RUN mkdir -p /app/storage/logs

# Ejecutar migraciones y luego limpiar cachés
RUN php artisan migrate --force
RUN php artisan cache:clear
RUN php artisan view:clear
RUN php artisan config:clear

# Instalamos Octane con Swoole
RUN php artisan octane:install --server="swoole"

# Exponemos el puerto
EXPOSE 8000

# Comando para iniciar Octane
CMD ["php", "artisan", "octane:start", "--server=swoole", "--host=0.0.0.0"]
