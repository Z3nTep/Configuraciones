#!/bin/bash

# Actualizar sistema
sudo apt update

# Instalar MySQL server (en lugar de solo el cliente)
sudo apt install -y mysql-server

# Crear base de datos y usuario para WordPress localmente
sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS wordpressdb01;
CREATE USER 'asix01'@'localhost' IDENTIFIED BY 'Sup3rins3gura!';
GRANT ALL PRIVILEGES ON wordpressdb01.* TO 'asix01'@'localhost';
FLUSH PRIVILEGES;
EOF

# Instalar dependencias de Apache y PHP
sudo apt install -y apache2 \
                 ghostscript \
                 libapache2-mod-php \
                 php \
                 php-bcmath \
                 php-curl \
                 php-imagick \
                 php-intl \
                 php-json \
                 php-mbstring \
                 php-mysql \
                 php-xml \
                 php-zip \
                 zip

# Directorio local para WordPress (sin EFS)
sudo mkdir -p /var/www/wordpress

# Descargar WordPress si no existe
if [ ! -d /var/www/wordpress/wp-admin ]; then
    curl -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
    sudo tar zx -C /var/www --strip-components=1 -f /tmp/wordpress.tar.gz
    sudo chown -R www-data:www-data /var/www/wordpress
    rm /tmp/wordpress.tar.gz
fi

# Añadir archivo para ver IP interna (opcional, útil en clusters)
sudo tee /var/www/wordpress/ip-interna.php << 'EOF'
<?php echo "IP interna: " . shell_exec("hostname -I"); ?>
EOF
sudo chown www-data:www-data /var/www/wordpress/ip-interna.php

# Configuración de Apache
sudo tee /etc/apache2/sites-available/wordpress.conf << 'EOF'
<VirtualHost *:80>
    DocumentRoot /var/www/wordpress
    <Directory /var/www/wordpress>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    <Directory /var/www/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Habilitar sitio y módulos
sudo a2ensite wordpress
sudo a2enmod rewrite
sudo a2dissite 000-default
sudo systemctl reload apache2

# Configurar wp-config.php si no existe
if [ ! -f /var/www/wordpress/wp-config.php ]; then
    sudo -u www-data cp /var/www/wordpress/wp-config-sample.php /var/www/wordpress/wp-config.php

    # Reemplazar valores por los locales
    sudo -u www-data sed -i "s/database_name_here/wordpressdb01/" /var/www/wordpress/wp-config.php
    sudo -u www-data sed -i "s/username_here/asix01/" /var/www/wordpress/wp-config.php
    sudo -u www-data sed -i "s/password_here/Sup3rins3gura!/" /var/www/wordpress/wp-config.php
    sudo -u www-data sed -i "s/localhost/localhost/" /var/www/wordpress/wp-config.php

    # Permitir actualizaciones/plugins vía filesystem
    echo "define('FS_METHOD', 'direct');" | sudo -u www-data tee -a /var/www/wordpress/wp-config.php
fi

echo "✅ Instalación de WordPress completada. Accede desde tu navegador."
