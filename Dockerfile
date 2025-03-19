# Use official Ubuntu as a base image
FROM kirby-cms:22.04

ENV LANG=de_DE.UTF-8

# Set environment variables to prevent some prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install Apache2, PHP, and necessary extensions
RUN apt-get update && apt-get install -y \
    php-apcu-all-dev \
    php-intl \
    php-memcache-all-dev \
    imagemagick \
    memcached \
    sqlite3 php-sqlite3 \
    mariadb-server php-mysql \
    locales-all

#     php-xdebug

RUN echo 'apc.enabled=1' >> /etc/php/8.1/cli/conf.d/20-apcu.ini
RUN echo 'apc.enable_cli=1' >> /etc/php/8.1/cli/conf.d/20-apcu.ini

# checkout the kirby sourcecode:
#   > cd src && git clone https://github.com/getkirby/kirby.git
#
RUN rm -fr /var/www/html/kirby
COPY --chown=www-data:www-data src/kirby /var/www/html/kirby

# checkout the kirby versions plugin:
#   > cd src && git clone https://github.com/lukasbestle/kirby-versions.git
RUN rm -fr site/plugins/versions
COPY --chown=www-data:www-data src/kirby-versions site/plugins/versions

# additional dev packages
RUN cd /var/www/html/kirby && composer require --dev friendsofphp/php-cs-fixer:3.52.1
RUN cd /var/www/html/kirby && composer require --dev phpunit/phpunit:10.5.38 --with-all-dependencies
RUN cd /var/www/html/kirby && composer require --dev vimeo/psalm:5.26.1 --with-all-dependencies
RUN cd /var/www/html/kirby && composer require --dev phpmd/phpmd

# fix permissions
#RUN find /var/www/html | xargs chown www-data:www-data

