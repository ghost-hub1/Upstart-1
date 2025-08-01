FROM php:8.2-apache

# Install required system libraries
RUN apt-get update && apt-get install -y \
    libzip-dev \
    zip \
    unzip \
    && docker-php-ext-configure zip \
    && docker-php-ext-install zip mbstring

# Enable Apache modules
RUN a2enmod rewrite headers

# Secure Apache headers
RUN echo "ServerSignature Off" >> /etc/apache2/apache2.conf && \
    echo "ServerTokens Prod" >> /etc/apache2/apache2.conf && \
    echo "Header set X-Content-Type-Options nosniff" >> /etc/apache2/apache2.conf && \
    echo "Header always unset X-Powered-By" >> /etc/apache2/apache2.conf && \
    echo "Header always set X-Frame-Options DENY" >> /etc/apache2/apache2.conf && \
    echo "Header always set X-XSS-Protection \"1; mode=block\"" >> /etc/apache2/apache2.conf

# Copy project files (adjust as needed)
COPY . /var/www/html/

# Clean up and lock permissions
RUN rm -rf /var/www/html/.git* /var/www/html/*.log /var/www/html/*.bak /var/www/html/*~ \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 750 /var/www/html

# Optional .htaccess rules
RUN touch /var/www/html/.htaccess && \
    echo "Options -Indexes" >> /var/www/html/.htaccess && \
    echo "RewriteEngine On" >> /var/www/html/.htaccess

# Set working dir
WORKDIR /var/www/html

# Change Apache port for Render
EXPOSE 10000
RUN sed -i 's/80/10000/g' /etc/apache2/ports.conf /etc/apache2/sites-enabled/000-default.conf

# Start Apache
CMD ["apache2-foreground"]
