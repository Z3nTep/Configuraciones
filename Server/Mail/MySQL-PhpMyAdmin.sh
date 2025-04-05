#!/bin/bash

# Variables
MYSQL_ROOT_PASSWORD="rootpassword"
MAIL_DB_USER="mailuser"
MAIL_DB_PASSWORD="Contrasenya123!"

PHP_MYADMIN_USER="phpmyadmin"
PHP_MYADMIN_PASSWORD="supersecretpasswd"
DOMAIN="dominio.lan"

# Actualizar paquetes
echo "Actualizando paquetes..."
apt-get update -y && apt-get upgrade -y

# Instalar MySQL
echo "Instalando MySQL..."
apt-get install -y mysql-server

# Configurar seguridad de MySQL
echo "Configurando seguridad de MySQL..."
mysql_secure_installation <<EOF
y       # Activar validate password plugin
1       # Nivel de seguridad STRONG (elige 0, 1 o 2 según necesites)
$MYSQL_ROOT_PASSWORD
$MYSQL_ROOT_PASSWORD
y       # Continuar con la contraseña proporcionada
y       # Eliminar usuarios anónimos
y       # Deshabilitar acceso remoto a root
y       # Eliminar base de datos de prueba
y       # Recargar privilegios
EOF

# Crear base de datos y usuario para phpMyAdmin y tablas específicas
echo "Creando base de datos, usuario y tablas específicas..."
mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF
CREATE DATABASE mailserver;
CREATE USER '$MAIL_DB_USER'@'localhost' IDENTIFIED BY '$MAIL_DB_PASSWORD';
GRANT ALL PRIVILEGES ON mailserver.* TO '$MAIL_DB_USER'@'localhost';
UNINSTALL COMPONENT "file://component_validate_password";
FLUSH PRIVILEGES;

USE mailserver;

-- Crear tabla virtual_domains
CREATE TABLE virtual_domains (
    id INT(11) NOT NULL AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    active BOOLEAN NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Crear tabla virtual_users
CREATE TABLE virtual_users (
    id INT(11) NOT NULL AUTO_INCREMENT,
    domain_id INT(11) NOT NULL,
    password VARCHAR(206) NOT NULL,
    email VARCHAR(100) NOT NULL,
    quota VARCHAR(10) NOT NULL,
    active BOOLEAN NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY email (email),
    FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Crear tabla virtual_aliases
CREATE TABLE virtual_aliases (
    id INT(11) NOT NULL AUTO_INCREMENT,
    domain_id INT(11) NOT NULL,
    source VARCHAR(100) NOT NULL,
    destination VARCHAR(100) NOT NULL,
    active BOOLEAN NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Insertar datos en la tabla virtual_domains
INSERT INTO virtual_domains (id, name, active) VALUES 
(1, 'idumont.lan', true);

-- Insertar datos en la tabla virtual_users
INSERT INTO virtual_users (id, domain_id, password, email, quota, active) VALUES 
(1, 1, MD5('adminpassword'), 'admin@dominio.lan', '0', true),
(2, 1, MD5('user1password'), 'user1@dominio.lan', '0', true),
(3, 1, MD5('user2password'), 'user2@dominio.lan', '0', true),
(4, 1, MD5('postmasterpassword'), 'postmaster@dominio.lan', '0', true);

-- Insertar datos en la tabla virtual_aliases
INSERT INTO virtual_aliases (id, domain_id, source, destination, active) VALUES 
(1, 1, 'info@dominio.lan', 'admin@dominio.lan', true),
(2, 1, 'support@dominio.lan', 'admin@dominio.lan', true),
(3, 1, 'sales@dominio.lan', 'user1@dominio.lan', true);
EOF

echo "Base de datos y tablas creadas correctamente."

# Instalar Apache y PHP
echo "Instalando Apache y PHP..."
apt-get install -y apache2 php libapache2-mod-php php-mysql php-opcache php-apcu php-mbstring

# Instalar phpMyAdmin
echo "Instalando phpMyAdmin..."
apt-get install -y phpmyadmin

# Reinstalamos el modulo para las políticas de contraseña en MySQL
mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF
INSTALL COMPONENT "file://component_validate_password";
EOF

# Configurar Apache para phpMyAdmin
echo "Configurando Apache para phpMyAdmin..."
cat <<EOF > /etc/apache2/sites-available/$DOMAIN.conf
<VirtualHost *:80>
    ServerName $DOMAIN
    DocumentRoot /usr/share/phpmyadmin

    <Directory /usr/share/phpmyadmin>
        Options FollowSymLinks
        DirectoryIndex index.php

        <FilesMatch \.php$>
            SetHandler application/x-httpd-php
        </FilesMatch>

        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

a2ensite $DOMAIN.conf
systemctl reload apache2

# Configurar SSL (opcional)
echo "Configurando SSL..."
apt-get install -y openssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/phpmyadmin.key \
  -out /etc/ssl/certs/phpmyadmin.crt

sudo cp /etc/ssl/certs/phpmyadmin.crt /usr/local/share/ca-certificates/

sudo update-ca-certificates

cat <<EOF >> /etc/apache2/sites-available/$DOMAIN.conf
<VirtualHost *:443>
    ServerName $DOMAIN
    DocumentRoot /usr/share/phpmyadmin
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/phpmyadmin.crt
    SSLCertificateKeyFile /etc/ssl/private/phpmyadmin.key

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

a2enmod ssl && systemctl reload apache2

echo "Instalación y configuración completadas."