#!/bin/bash
sudo apt update
sudo apt install -y mysql-client unzip php-cli
sudo snap install --classic aws-cli

# Instalar Composer y AWS SDK para PHP
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
cd /srv/www/wordpress || mkdir -p /srv/www/wordpress && cd /srv/www/wordpress
sudo composer require aws/aws-sdk-php

# Parámetros de AWS Secrets Manager
SECRET_NAME='Pal-Wordrpess'
REGION="us-east-1"

# Obtener credenciales desde Secrets Manager (requiere que la instancia tenga un role de IAM apropiado)
DB_INFO=$(aws secretsmanager get-secret-value --region $REGION --secret-id $SECRET_NAME --query SecretString --output text)
DB_USER=$(echo $DB_INFO | jq -r .username)
DB_PASS=$(echo $DB_INFO | jq -r .password)
DB_HOST=$(echo $DB_INFO | jq -r .host)

# Si las variables llevan -, se debe hacer de esta forma:
WP_DB_USER=$(jq -r '."wp-datauser"' <<< "$DB_INFO")
WP_DB_NAME=$(jq -r '."wp-database"' <<< "$DB_INFO")
WP_DB_PASS=$(jq -r '."wp-datapass"' <<< "$DB_INFO")

tee crea-wordpress-db.sql <<EOF
CREATE DATABASE IF NOT EXISTS $WP_DB_NAME;
CREATE USER IF NOT EXISTS '$WP_DB_USER'@'%' IDENTIFIED BY '$WP_DB_PASS';
GRANT ALL PRIVILEGES ON $WP_DB_NAME.* TO '$WP_DB_USER'@'%';
FLUSH PRIVILEGES;
exit
EOF

# Crear la base de datos en RDS, usando las credenciales de admin que también puede estar en SecretsManager si lo prefieres
cat crea-wordpress-db.sql | sudo mysql -u $DB_USER -p$DB_PASS -h $DB_HOST


sudo apt update
sudo apt install -y apache2 \
                 ghostscript \
                 libapache2-mod-php \
                 mysql-client \
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

sudo apt install -y nfs-common

##
##
sudo mkdir -p /srv/www

# cal informar el mount point generat prèviament
unitat_compartida=fs-0e1a4ebf4b35b196a.efs.us-east-1.amazonaws.com:/

punt_de_muntatge=/srv/www

sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $unitat_compartida $punt_de_muntatge 

# si no existeix el directori és que és el 1er cop i caldrà descarregar-lo
if [ ! -d /srv/www/wordpress ]; then  curl https://wordpress.org/latest.tar.gz | sudo tar zx -C /srv/www ; sudo chown www-data: /srv/www/wordpress;  fi

# com que acabem de crear la instància caldrà afegir a /etc/fstab el recurs compartit pq el munte de nou quan reiniciem
grep $unitat_compartida /etc/fstab || sudo tee -a /etc/fstab << EOF
$unitat_compartida $punt_de_muntatge nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0
EOF

# ip interna # per validar que hi ha diferents instàncies
sudo tee /srv/www/wordpress/ip-interna.php << EOF
ip interna: <?php echo shell_exec("hostname -I"); ?>
EOF

sudo chown -R www-data:www-data /srv/www

##
##
# AllowOverride Limit Options FileInfo
sudo tee /etc/apache2/sites-available/wordpress.conf << EOF
<VirtualHost *:80>
    DocumentRoot /srv/www/wordpress
    <Directory /srv/www/wordpress>
        Options FollowSymLinks
        AllowOverride All
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory /srv/www/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
EOF

##
##
sudo a2ensite wordpress
sudo a2enmod rewrite
sudo a2dissite 000-default
sudo service apache2 reload

creat_en_aquest=false
if [ ! -f /srv/www/wordpress/wp-config.php ]; then 
  sudo -u www-data cp /srv/www/wordpress/wp-config-sample.php /srv/www/wordpress/wp-config.php; 
  creat_en_aquest=true; 
fi

if $creat_en_aquest; then
  # Usar sed para configurar las variables obtenidas dinámicamente
  sudo -u www-data sed -i "s/database_name_here/$DB_NAME/" /srv/www/wordpress/wp-config.php
  sudo -u www-data sed -i "s/username_here/$DB_USER/" /srv/www/wordpress/wp-config.php
  sudo -u www-data sed -i "s/password_here/$DB_PASS/" /srv/www/wordpress/wp-config.php
  sudo -u www-data sed -i "s/localhost/$DB_HOST/" /srv/www/wordpress/wp-config.php
  echo "define('FS_METHOD', 'direct');" | sudo -u www-data tee -a /srv/www/wordpress/wp-config.php

  # Añadir lógica para X-Forwarded-Proto (justo antes de la línea That's all, stop editing!)
  sudo -u www-data sed -i "/That's all, stop editing!/i if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {\n    \$_SERVER['HTTPS'] = 'on';\n}" /srv/www/wordpress/wp-config.php
fi