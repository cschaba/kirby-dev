# Use official Ubuntu as a base image
FROM ubuntu:22.04

#ENV LANG=de_DE.UTF-8

# Set environment variables to prevent some prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install Apache2, PHP, and necessary extensions
RUN apt-get update && apt-get install -y \
    apache2 \
    curl \
    unzip \
    git \
    php \
    libapache2-mod-php \
    php-apcu \
    php-cli \
    php-common \
    php-curl \
    php-ctype \
    php-fpm \
    php-gd \
    php-imagick \
    php-json \
    php-memcached \
    php-mbstring \
    php-xml \
    php-zip \
    php-apcu-all-dev \
    php-intl \
    php-memcache-all-dev \
    php-xdebug \
    imagemagick \
    memcached \
    sqlite3 php-sqlite3 \
    mariadb-server php-mysql \
    locales-all

# Enable Apache2 mod_rewrite
RUN a2enmod rewrite

# Log output to stdout/stderr to have it in the docker logfile management
RUN sed -i -E 's+CustomLog .*$+CustomLog /dev/stdout combined+;' /etc/apache2/sites-enabled/000-default.conf
RUN sed -i -E 's+ErrorLog .*$+ErrorLog /dev/stderr+;' /etc/apache2/sites-enabled/000-default.conf

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# check composer works
RUN composer --version

# Allow .htaccess
RUN sed -i -E 's+(.*DocumentRoot.*)+\tDocumentRoot /var/www/html\n\n\t<Directory "/var/www/html">\n\t\tAllowOverride All\n\t</Directory>\n+;' /etc/apache2/sites-enabled/000-default.conf

# enable APCs
RUN echo 'apc.enabled=1' >> /etc/php/8.1/cli/conf.d/20-apcu.ini
RUN echo 'apc.enable_cli=1' >> /etc/php/8.1/cli/conf.d/20-apcu.ini
RUN echo "xdebug.mode=coverage" >> /etc/php/8.1/cli/conf.d/20-xdebug.ini

# Set the working directory for HTML files (this will be linked to the host volume)
WORKDIR /var/www/html
RUN chsh -s /bin/bash www-data
RUN chown -R www-data:www-data /var/www

# install the plainkit first
#   > cd src && git clone https://github.com/getkirby/plainkit.git
#
RUN rm -fr /var/www/html/
COPY --chown=www-data:www-data src/plainkit /var/www/html
RUN rm -fr /var/www/html/.git

# checkout the kirby sourcecode:
#   > cd src && git clone https://github.com/getkirby/kirby.git
#
RUN rm -fr /var/www/html/kirby
COPY --chown=www-data:www-data src/kirby /var/www/html/kirby
RUN rm -fr /var/www/html/kirby/.git

# checkout the kirby versions plugin:
#   > cd src && git clone https://github.com/lukasbestle/kirby-versions.git
RUN rm -fr /var/www/html/site/plugins/versions
COPY --chown=www-data:www-data src/kirby-versions /var/www/html/site/plugins/versions
RUN rm -fr /var/www/html/site/plugins/versions/.git

# additional dev packages
RUN cd /var/www/html/kirby && composer require --dev friendsofphp/php-cs-fixer:3.52.1
RUN cd /var/www/html/kirby && composer require --dev phpunit/phpunit:10.5.38 --with-all-dependencies
RUN cd /var/www/html/kirby && composer require --dev vimeo/psalm:5.26.1 --with-all-dependencies
RUN cd /var/www/html/kirby && composer require --dev phpmd/phpmd

RUN cd /var/www/html/site/plugins/versions && composer require --dev friendsofphp/php-cs-fixer
RUN cd /var/www/html/site/plugins/versions && composer require --dev phpunit/phpunit
RUN cd /var/www/html/site/plugins/versions && composer require --dev vimeo/psalm
RUN cd /var/www/html/site/plugins/versions && composer require --dev phpmd/phpmd

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

# fix permissions
RUN echo "fixing permissions... will take some seconds..."
RUN find /var/www | xargs chown www-data:www-data

# define volumes which will contain users data
VOLUME /var/www/html/cache
VOLUME /var/www/html/content
VOLUME /var/www/html/media

# Expose port 80
EXPOSE 80

# Start Apache2 when the container runs
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
CMD ["bash", "/entrypoint.sh"]
