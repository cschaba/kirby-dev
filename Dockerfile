# Use official Ubuntu as a base image
FROM ubuntu:latest

# Set environment variables to prevent some prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install Apache2, PHP, and necessary extensions
RUN apt-get update && apt-get install -y \
    apache2 \
    php \
    php-apcu \
    php-cli \
    php-common \
    php-curl \
    php-fpm \
    php-gd \
    php-imagick \
    php-json \
    php-memcached \
    php-mbstring \
    php-xml \
    php-zip \
    libapache2-mod-php \
    curl \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache2 mod_rewrite
RUN a2enmod rewrite

# Allow .htaccess
RUN sed -i -E 's+(.*DocumentRoot.*)+\tDocumentRoot /var/www/html\n\n\t<Directory "/var/www/html">\n\t\tAllowOverride All\n\t</Directory>\n+;' /etc/apache2/sites-enabled/000-default.conf

# Log output to stdout/stderr to have it in the docker logfile management
RUN sed -i -E 's+CustomLog .*$+CustomLog /dev/stdout combined+;' /etc/apache2/sites-enabled/000-default.conf
RUN sed -i -E 's+ErrorLog .*$+ErrorLog /dev/stderr+;' /etc/apache2/sites-enabled/000-default.conf

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# check composer works
RUN composer --version

# install kirby via composer
# https://getkirby.com/docs/guide/install-guide/composer
RUN cd /var/www/ && rm html/* && composer create-project getkirby/starterkit html
RUN mkdir -p /var/www/html/media && touch /var/www/html/media/index.html

# enable support for HTTPS behind a proxy
COPY <<-newindexphp index.php
<?php

if (isset(\$_SERVER['HTTP_X_FORWARDED_FOR'])) {
    if (strpos(\$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false) {
            \$_SERVER['HTTPS'] = true;
    }
}

require 'kirby/bootstrap.php';

echo (new Kirby)->render();

newindexphp

# install some kirby plugins
RUN composer require getkirby/cli

# Set the working directory for HTML files (this will be linked to the host volume)
WORKDIR /var/www/html
RUN chown -R www-data:www-data /var/www/html

# define volumes which will contain users data
VOLUME /var/www/html/content
VOLUME /var/www/html/media
VOLUME /var/www/html/site

# Expose port 80
EXPOSE 80

# Start Apache2 when the container runs
CMD ["apache2ctl", "-D", "FOREGROUND"]
