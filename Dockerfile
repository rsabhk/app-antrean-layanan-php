FROM php:8.1-fpm as build

LABEL Maintainer="Anca Yuliansyah <anca@rsabhk.co.id>" \
      Description="Nginx, PHP-FM and Laravel for Antrean Layanan"

# Get frequently used tools
RUN apt-get update && apt-get install -y \
    build-essential \
    libicu-dev \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    locales \
    zip \
    unzip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    git \
    curl \
    wget \
    libpq-dev \
    libmagickwand-dev

RUN docker-php-ext-configure zip

RUN pecl install imagick \
 && docker-php-ext-enable imagick

RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql

RUN docker-php-ext-install \
        bcmath \
        mbstring \
        pcntl \
        intl \
        zip \
	opcache \
        pdo \
        pdo_pgsql \
        pgsql 

RUN docker-php-ext-install gd
       
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy existing app directory
#COPY ./be-contact-center /var/www
WORKDIR /var/www


# Configure non-root user.
ARG PUID=1003
ENV PUID ${PUID}
ARG PGID=1003
ENV PGID ${PGID}
ARG DOC_ROOT

RUN groupmod -o -g ${PGID} www-data && \
    usermod -o -u ${PUID} -g www-data www-data

#RUN groupadd -g 1000 www
#RUN useradd -u 1000 -ms /bin/bash -g www www

#RUN chown -R www-data:www /var/www

# Copy and run composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


COPY --chown=www-data:www-data ./${DOC_ROOT}/env.prod /var/www/.env
COPY --chown=www-data:www-data ./${DOC_ROOT} /var/www
#COPY ./cron/*.sh /etc/
RUN composer update

RUN composer install --no-interaction

#COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# For Laravel Installations

RUN php artisan key:generate
RUN php artisan cache:clear

RUN chown -R www-data:www-data .
RUN chmod -R 755 ./storage
USER www-data

EXPOSE 9000

CMD ["php-fpm"]

# ### STAGE 2: Run ###
# FROM nginx:1.17.1-alpine
# #COPY nginx.conf /etc/nginx/nginx.conf
# USER www-data
# WORKDIR /var/www
# COPY --from=build /var/www/public /var/www/public
