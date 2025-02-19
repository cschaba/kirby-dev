# Use official Ubuntu as a base image
FROM ubuntu:latest

# Set environment variables to prevent some prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install Apache2, PHP, and necessary extensions
RUN apt-get update && apt-get install -y \
    apache2 \
    php \
    libapache2-mod-php \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache2 mod_rewrite
RUN a2enmod rewrite

COPY src/index.php /var/www/html/
# Set the working directory for HTML files (this will be linked to the host volume)
WORKDIR /var/www/html

# Expose port 80
EXPOSE 80

# Start Apache2 when the container runs
CMD ["apache2ctl", "-D", "FOREGROUND"]
