# cargamos imagen de php nodo alpine super reducida

# construimos una imagen partiendo del asistente de octane. Usamos una imagen base optimizada para Laravel, 
# que incluye PHP y todos los paquetes requeridos.
# Podemos usar siempre esta para construir nuestros proyectos de laravel
FROM elrincondelisma/octane:latest 

#Instalamos Composer descargando el instalador oficial y configurándolo en /usr/local/bin.
Run curl -sS https://getcomposer.org/installer | php -- \
  --install-dir=/usr/local/bin --filename=composer

# Copiamos Composer y Roadrunner desde sus imágenes oficiales para habilitar su uso en el contenedor.
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY --from=spiralscout/roadrunner:2.4.2 /usr/bin/rr /usr/bin/rr

# Configuramos el directorio de trabajo principal del contenedor como /app.
WORKDIR /app
# Copiamos todos los archivos del proyecto local al directorio de trabajo en el contenedor.
COPY . .
# Eliminamos la carpeta vendor y el archivo composer.lock para evitar problemas de dependencias 
# causados por diferencias entre versiones de php en entornos de desarrollo y producción.
RUN rm -rf /app/vendor
RUN rm -rf /app/composer.lock
# Instalamos las dependencias necesarias para Laravel y Octane, incluyendo Roadrunner.
RUN composer install
RUN composer require laravel/octane spiral/roadrunner
# Configuramos el entorno copiando el archivo env.example como .env, ya que este archivo puede faltar tras un pull de git.
COPY .env.example .env
# Creamos el directorio de logs dentro de la carpeta de storage, esencial para Laravel.
RUN mkdir -p /app/storage/logs
# Limpiamos las cachés de la aplicación para evitar configuraciones desactualizadas o conflictos.
RUN php artisan cache:clear
RUN php artisan view:clear
RUN php artisan config:clear
# Instalamos Octane con el servidor Swoole y configuramos su inicio para escuchar todas las direcciones IP.
RUN php artisan octane:install --server="swoole"
RUN php artisan octane:start --server="swoole" --host="0.0.0.0"

# Exponemos el puerto 8000 para permitir conexiones al servidor de octane porque ese está escuchando en el puerto 8000
EXPOSE 8000