#!/bin/bash

# Variables
DOMAIN="idumont.lan"  # Cambiado a tu dominio
EMAIL="root@idumont.lan"  # Cambiado a tu email
APACHE_LOG_DIR="/var/log/apache2"

# Crear el directorio del sitio y el archivo index.html
echo "Creando el directorio del sitio y el archivo index.html..."
sudo mkdir -p /var/www/html/$DOMAIN
sudo bash -c "cat <<EOF > /var/www/html/$DOMAIN/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Bienvenido a $DOMAIN</title>
</head>
<body>
    <center><h1>Hola Este es el sitio de $DOMAIN!</h1></center>
</body>
</html>
EOF"
sudo chown -R www-data:www-data /var/www/html/$DOMAIN
sudo chmod -R 755 /var/www/html/$DOMAIN

# Configurar el VirtualHost para HTTP (puerto 80)
echo "Configurando el VirtualHost para HTTP (puerto 80)..."
sudo bash -c "cat <<EOF > /etc/apache2/sites-available/$DOMAIN.conf
<VirtualHost *:80>
    ServerAdmin $EMAIL
    ServerName $DOMAIN
    DocumentRoot /var/www/html/$DOMAIN
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
    <Directory /var/www/html/$DOMAIN>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF"

# Verificar la sintaxis de la configuración
echo "Verificando la sintaxis de la configuración..."
sudo apache2ctl configtest

# Habilitar el sitio y el módulo rewrite
echo "Habilitando el sitio y el módulo rewrite..."
sudo a2dissite 000-default.conf 2>/dev/null
sudo a2ensite $DOMAIN.conf
sudo a2enmod rewrite

# Reiniciar Apache2 para aplicar los cambios
echo "Reiniciando Apache2 para aplicar los cambios..."
sudo systemctl restart apache2

# Generar un certificado SSL autofirmado
echo "Generando un certificado SSL autofirmado..."
sudo openssl genpkey -algorithm RSA -out /etc/ssl/private/$DOMAIN.key
sudo openssl req -x509 -new -nodes -key /etc/ssl/private/$DOMAIN.key \
    -sha256 -days 365 -out /etc/ssl/certs/$DOMAIN.crt -subj "/CN=$DOMAIN"

# Configurar el VirtualHost para HTTPS (puerto 443)
echo "Configurando el VirtualHost para HTTPS (puerto 443)..."
sudo bash -c "cat <<EOF > /etc/apache2/sites-available/$DOMAIN.conf
<VirtualHost *:80>
    ServerName $DOMAIN
    Redirect permanent / https://$DOMAIN/
</VirtualHost>

<IfModule mod_ssl.c>
    <VirtualHost *:443>
        ServerAdmin $EMAIL
        ServerName $DOMAIN
        DocumentRoot /var/www/html/$DOMAIN
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

        SSLEngine on
        SSLCertificateFile /etc/ssl/certs/$DOMAIN.crt
        SSLCertificateKeyFile /etc/ssl/private/$DOMAIN.key

        Protocols h2 http/1.1

        <Directory /var/www/html/$DOMAIN>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>
    </VirtualHost>
</IfModule>
EOF"

# Habilitar los módulos necesarios
echo "Habilitando los módulos necesarios..."
sudo a2enmod ssl http2 headers

# Verificar la sintaxis de la configuración nuevamente.
echo "Verificando la sintaxis de la configuración nuevamente..."
sudo apache2ctl configtest

# Reiniciar Apache2 para aplicar los cambios finales.
echo "Reiniciando Apache2..."
sudo systemctl restart apache2

# Agregar el certificado al almacén de confianza del sistema.
echo "Agregando el certificado al almacén de confianza del sistema..."
sudo cp /etc/ssl/certs/$DOMAIN.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

echo "¡La configuración se ha completado exitosamente para $DOMAIN!"
