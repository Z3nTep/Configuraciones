#!/bin/bash
set -e

NEXTCLOUD_DOWNLOAD_URL="https://download.nextcloud.com/server/releases/latest.tar.bz2"
DOCUMENT_ROOT="/var/www/html"

echo "[Nextcloud OpenSUSE Init] Iniciando..."

# Descargar Nextcloud
if [ ! -f "${DOCUMENT_ROOT}/version.php" ]; then
    echo "Descargando Nextcloud..."
    curl -fsSL -o /tmp/nextcloud.tar.bz2 "${NEXTCLOUD_DOWNLOAD_URL}"
    tar -xjf /tmp/nextcloud.tar.bz2 -C "${DOCUMENT_ROOT}" --strip-components=1
    rm /tmp/nextcloud.tar.bz2
else
    echo "Nextcloud instalado."
fi

# Aplicar permisos
echo "Aplicando permisos restrictivos..."
chown -R wwwrun:www "${DOCUMENT_ROOT}"
find "${DOCUMENT_ROOT}/" -type d -exec chmod 750 {} \;
find "${DOCUMENT_ROOT}/" -type f -exec chmod 640 {} \;

echo "Arranque finalizado."

exec "$@"
