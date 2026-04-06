FROM opensuse/leap:15.5

LABEL maintainer="Configuraciones All-In-One Nextcloud"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# Instalar dependencias
RUN zypper --non-interactive refresh && \
    zypper --non-interactive install -y \
        apache2 apache2-mod_php8 php8 php8-mysql php8-gd php8-mbstring \
        php8-curl php8-zip php8-bz2 php8-intl php8-openssl php8-bcmath \
        php8-gmp php8-pcntl php8-imagick php8-exif php8-fileinfo \
        php8-redis php8-apcu php8-opcache curl tar gzip bzip2 sudo jq && \
    zypper clean -a

# Habilitar módulos
RUN sed -i 's/^APACHE_MODULES="\(.*\)"/APACHE_MODULES="\1 php8 rewrite headers env dir setenvif ssl"/' /etc/sysconfig/apache2 || true

# Configurar Apache
RUN echo "ServerSignature Off" >> /etc/apache2/httpd.conf && \
    echo "ServerTokens Prod" >> /etc/apache2/httpd.conf && \
    echo "ServerName localhost" >> /etc/apache2/httpd.conf && \
    sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/default-server.conf

# Preparar directorios
RUN mkdir -p /var/www/html && \
    chown -R wwwrun:www /var/www/html

# Configurar PHP
RUN echo "memory_limit = 512M" > /etc/php8/apache2/conf.d/nextcloud.ini && \
    echo "upload_max_filesize = 5G" >> /etc/php8/apache2/conf.d/nextcloud.ini && \
    echo "post_max_size = 5G" >> /etc/php8/apache2/conf.d/nextcloud.ini && \
    echo "max_execution_time = 3600" >> /etc/php8/apache2/conf.d/nextcloud.ini && \
    echo "date.timezone = UTC" >> /etc/php8/apache2/conf.d/nextcloud.ini && \
    echo "opcache.enable=1" >> /etc/php8/apache2/conf.d/nextcloud.ini && \
    echo "opcache.interned_strings_buffer=32" >> /etc/php8/apache2/conf.d/nextcloud.ini && \
    echo "opcache.max_accelerated_files=10000" >> /etc/php8/apache2/conf.d/nextcloud.ini && \
    echo "opcache.memory_consumption=128" >> /etc/php8/apache2/conf.d/nextcloud.ini && \
    echo "opcache.save_comments=1" >> /etc/php8/apache2/conf.d/nextcloud.ini && \
    echo "opcache.revalidate_freq=1" >> /etc/php8/apache2/conf.d/nextcloud.ini

# Copiar script de inicio
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/sbin/start_apache2", "-D", "FOREGROUND"]
