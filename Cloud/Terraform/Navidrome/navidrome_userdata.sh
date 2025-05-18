#!/bin/bash
set -e

# Instala dependencias
yum update -y
yum install -y ffmpeg wget tar git

# Variables
ND_VERSION="0.52.5"
ND_USER="navidrome"
ND_HOME="/opt/navidrome"
ND_DATA="/var/lib/navidrome"

# Crea usuario y carpetas
useradd --system --no-create-home --shell /sbin/nologin $ND_USER || true
mkdir -p $ND_HOME $ND_DATA /srv/music
chown -R $ND_USER:$ND_USER $ND_HOME $ND_DATA /srv/music

# Descarga y extrae Navidrome
cd /tmp
wget https://github.com/navidrome/navidrome/releases/download/v${ND_VERSION}/navidrome_${ND_VERSION}_linux_amd64.tar.gz
tar -xzf navidrome_${ND_VERSION}_linux_amd64.tar.gz
mv navidrome $ND_HOME/
chown $ND_USER:$ND_USER $ND_HOME/navidrome
chmod +x $ND_HOME/navidrome

# Clona canciones de ejemplo
git clone https://github.com/Z3nTep/sounds-loops.git /srv/music

# Lanza Navidrome en background (puerto 4533 por defecto)
sudo -u navidrome nohup $ND_HOME/navidrome --musicfolder /srv/music --datafolder $ND_DATA > /var/log/navidrome.log 2>&1 &
