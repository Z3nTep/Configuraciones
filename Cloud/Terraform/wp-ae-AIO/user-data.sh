#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

sudo apt update
sudo apt install -y mysql-client

tee crea-wordpress-db.sql <<EOF
CREATE DATABASE IF NOT EXISTS wordpressdb01;
CREATE USER IF NOT EXISTS 'asix01'@'%' IDENTIFIED BY 'Sup3rins3gura!';
GRANT ALL PRIVILEGES ON wordpressdb01.* TO 'asix01'@'%';
FLUSH PRIVILEGES;
EOF

mysql -u admin -pUltr4ins3gur4! -h ${rds_endpoint} < crea-wordpress-db.sql

sudo apt install -y apache2 ghostscript libapache2-mod-php mysql-client php php-bcmath php-curl php-imagick php-intl php-json php-mbstring php-mysql php-xml php-zip zip nfs-common

sudo mkdir -p /srv/www

unitat_compartida=${efs_dns_name}:/
punt_de_muntatge=/srv/www

until sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $unitat_compartida $punt_de_muntatge; do
  sleep 5
done

if [ ! -d /srv/www/wordpress ]; then
  curl -s https://wordpress.org/latest.tar.gz | sudo tar zx -C /srv/www
  sudo chown -R www-data:www-data /srv/www/wordpress
fi

grep "$unitat_compartida" /etc/fstab || echo "$unitat_compartida $punt_de_muntatge nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" | sudo tee -a /etc/fstab

sudo tee /srv/www/wordpress/ip-interna.php <<EOF
ip interna: <?php echo shell_exec("hostname -I"); ?>
EOF

sudo chown -R www-data:www-data /srv/www

sudo tee /etc/apache2/sites-available/wordpress.conf <<EOF
<VirtualHost *:80>
    DocumentRoot /srv/www/wordpress
    <Directory /srv/www/wordpress>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

sudo a2ensite wordpress
sudo a2enmod rewrite
sudo a2dissite 000-default
sudo systemctl reload apache2

if [ ! -f /srv/www/wordpress/wp-config.php ]; then
  sudo -u www-data cp /srv/www/wordpress/wp-config-sample.php /srv/www/wordpress/wp-config.php
  sudo -u www-data sed -i 's/database_name_here/wordpressdb01/' /srv/www/wordpress/wp-config.php
  sudo -u www-data sed -i 's/username_here/asix01/' /srv/www/wordpress/wp-config.php
  sudo -u www-data sed -i 's/password_here/Sup3rins3gura!/' /srv/www/wordpress/wp-config.php
  sudo -u www-data sed -i "s/localhost/${rds_endpoint}/" /srv/www/wordpress/wp-config.php
  echo "define('FS_METHOD', 'direct');" | sudo -u www-data tee -a /srv/www/wordpress/wp-config.php
fi