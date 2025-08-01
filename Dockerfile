# ⚙️ Base: PHP 8.2 with Apache
FROM php:8.2-apache

# 🧩 Install necessary PHP extensions (e.g. OpenSSL, mbstring, zip, json)
RUN docker-php-ext-install openssl mbstring zip

# 🛠️ Enable Apache mod_rewrite (for router.php / stealth redirects)
RUN a2enmod rewrite headers

# 🔒 Harden Apache headers & disable signature leaks
RUN echo "ServerSignature Off" >> /etc/apache2/apache2.conf && \
    echo "ServerTokens Prod" >> /etc/apache2/apache2.conf && \
    echo "Header set X-Content-Type-Options nosniff" >> /etc/apache2/apache2.conf && \
    echo "Header always unset X-Powered-By" >> /etc/apache2/apache2.conf && \
    echo "Header always set X-Frame-Options DENY" >> /etc/apache2/apache2.conf && \
    echo "Header always set X-XSS-Protection \"1; mode=block\"" >> /etc/apache2/apache2.conf

# 🔐 Move sensitive files to secure internal path (not publicly served)
RUN mkdir -p /opt/secure_payload
COPY payload_core.b64 /opt/secure_payload/
COPY tokens.json /opt/secure_payload/
# COPY encryption_utils.php /opt/secure_payload/

# ⚙️ App source files (excluding `.git`, `payload_core.b64`, etc.)
COPY . /var/www/html/

# 🔍 Prevent Git and debug files from leaking
RUN rm -rf /var/www/html/.git* /var/www/html/*.log /var/www/html/*.bak /var/www/html/*~ \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 750 /var/www/html

# 🔁 Optional .htaccess security if used
RUN touch /var/www/html/.htaccess && \
    echo "Options -Indexes" >> /var/www/html/.htaccess && \
    echo "RewriteEngine On" >> /var/www/html/.htaccess

# 📍 Set working dir
WORKDIR /var/www/html

# 🚪 Render requires port 10000
EXPOSE 10000

# 🔄 Make Apache use Render’s port 10000
RUN sed -i 's/80/10000/g' /etc/apache2/ports.conf /etc/apache2/sites-enabled/000-default.conf

# 🚀 Launch Apache in foreground (as required by Render)
CMD ["apache2-foreground"]
