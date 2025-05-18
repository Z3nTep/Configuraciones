#!/bin/bash
set -e

yum update -y
yum install -y unzip wget git

OC_VERSION="0.1.2"
INSTALL_DIR="/opt/owncast"
SERVICE_USER="owncast"

# Crea usuario de sistema para Owncast (sin login)
if ! id -u $SERVICE_USER >/dev/null 2>&1; then
  useradd --system --home-dir $INSTALL_DIR --shell /sbin/nologin $SERVICE_USER
fi

# Crea directorio de instalación y cambia propietario
mkdir -p $INSTALL_DIR
chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR

# Descarga y descomprime Owncast
cd /tmp
wget https://github.com/owncast/owncast/releases/download/v${OC_VERSION}/owncast-${OC_VERSION}-linux-64bit.zip
unzip -o owncast-${OC_VERSION}-linux-64bit.zip -d $INSTALL_DIR
rm owncast-${OC_VERSION}-linux-64bit.zip
chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR

# DESCARGA BINARIO ESTÁTICO DE FFMPEG Y LO COLOCA EN EL DIRECTORIO DE OWNCAST
cd /tmp
wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz
tar -xf ffmpeg-release-amd64-static.tar.xz
cp ffmpeg-*-amd64-static/ffmpeg $INSTALL_DIR/ffmpeg
chmod +x $INSTALL_DIR/ffmpeg
chown $SERVICE_USER:$SERVICE_USER $INSTALL_DIR/ffmpeg
rm -rf ffmpeg-*-amd64-static ffmpeg-release-amd64-static.tar.xz

# Crea servicio systemd para Owncast
cat <<EOF > /etc/systemd/system/owncast.service
[Unit]
Description=Owncast Streaming Server
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/owncast
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now owncast
