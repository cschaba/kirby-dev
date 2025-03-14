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

# Set the working directory for HTML files (this will be linked to the host volume)
WORKDIR /var/www/html

# install kirby with plainkit via composer
# https://getkirby.com/docs/guide/install-guide/composer
RUN cd /var/www/ && rm html/* && composer create-project getkirby/plainkit html

# create the media folder
RUN mkdir -p /var/www/html/media && touch /var/www/html/media/index.html

# enable support for HTTPS behind a proxy
COPY <<-newindexphp /var/www/html/index.php
<?php

if (isset(\$_SERVER['HTTP_X_FORWARDED_FOR'])) {
    if (strpos(\$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false) {
            \$_SERVER['HTTPS'] = true;
    }
}

require 'kirby/bootstrap.php';

echo (new Kirby)->render();

newindexphp

# copy the site
COPY src/site /var/www/html/site

# install some kirby plugins
RUN composer require getkirby/cli

# install and configure the versions plugin
RUN composer require lukasbestle/kirby-versions
RUN <<initversions bash
tagName="initial"
cd /var/www/html/content
git init
git add -A
git config user.email "kirby@localhost"
git config user.name "Kirby"
git commit -m "Initial version"
git tag "\$tagName" -am "Initial version"
git checkout "\$tagName"
git branch -d master
initversions

# fix permissions
RUN chown -R www-data:www-data /var/www/html

# define volumes which will contain users data
VOLUME /var/www/html/content
VOLUME /var/www/html/media

# Expose port 80
EXPOSE 80

# Start Apache2 when the container runs
CMD ["apache2ctl", "-D", "FOREGROUND"]
