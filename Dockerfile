# Use official Ubuntu as a base image
FROM ubuntu:latest

# Set environment variables to prevent some prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install Apache2, PHP, and necessary extensions
RUN apt-get update && apt-get install -y \
    apache2 \
    php \
    php-cli \
    php-fpm \
    php-mbstring \
    php-xml \
    php-curl \
    php-json \
    php-mysqli \
    php-gd \
    libapache2-mod-php \
    curl \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache2 mod_rewrite
RUN a2enmod rewrite

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# check composer works
RUN composer --version

# install kirby via composer
# https://getkirby.com/docs/guide/install-guide/composer
RUN cd /var/www/ && rm html/* && composer create-project getkirby/starterkit html
RUN chown -R www-data:www-data /var/www/html

# Set the working directory for HTML files (this will be linked to the host volume)
WORKDIR /var/www/html

# define volumes which will contain users data
VOLUME /var/www/html/content
VOLUME /var/www/html/media
VOLUME /var/www/html/site

# Expose port 80
EXPOSE 80

# Start Apache2 when the container runs
CMD ["apache2ctl", "-D", "FOREGROUND"]
