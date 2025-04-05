#!/bin/bash
# Variables
DNS_IP="10.0.0.1"
MAIL_IP="10.0.0.2"
DOMAIN="dominio.lan"

# Actualizar paquetes
echo "Actualizando paquetes..."
sudo apt-get update -y && sudo apt-get upgrade -y

# Instalar BIND
echo "Instalando BIND..."
sudo apt-get install -y bind9 bind9utils bind9-doc

# Configurar zonas de DNS
echo "Configurando zonas de DNS..."
sudo bash -c "cat <<EOF > /etc/bind/named.conf.local
zone \"$DOMAIN\" {
    type master;
    file \"/etc/bind/db.$DOMAIN\";
};

zone \"0.10.in-addr.arpa\" {
    type master;
    file \"/etc/bind/db.10\";
};
EOF"

sudo bash -c "cat <<EOF > /etc/bind/db.$DOMAIN
\$TTL    604800
@       IN      SOA     ns.$DOMAIN. admin.$DOMAIN. (
                        2         ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL

; Servidores DNS
@       IN      NS      ns.$DOMAIN.
ns      IN      A       $DNS_IP

; Servidor de correo
@       IN      MX      10 mail.$DOMAIN.
mail    IN      A       $MAIL_IP
webmail IN      A       $MAIL_IP

; Otros equipos (opcional)
cliente IN      A       10.24.153.3
EOF"

# Crear archivo de zona inversa para la red 10.x.x.x
echo "Creando archivo de zona inversa..."
sudo bash -c "cat <<EOF > /etc/bind/db.10
\$TTL    604800
@       IN      SOA     ns.$DOMAIN. admin.$DOMAIN. (
                        2         ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL

@       IN      NS      ns.$DOMAIN.
1       IN      PTR     ns.$DOMAIN.
2       IN      PTR     mail.$DOMAIN.
2       IN      PTR     webmail.$DOMAIN.
EOF"

# Reiniciar BIND para aplicar cambios
echo "Reiniciando BIND..."
sudo systemctl restart bind9

# Verificar configuración y estado del servicio DNS
echo "Verificando configuración de BIND..."
sudo named-checkconf /etc/bind/named.conf.local && echo "named.conf.local verificado correctamente."
sudo named-checkzone $DOMAIN /etc/bind/db.$DOMAIN && echo "Zona directa verificada correctamente."
sudo named-checkzone 0.10.in-addr.arpa /etc/bind/db.10 && echo "Zona inversa verificada correctamente."

echo "Servidor DNS configurado exitosamente con el dominio $DOMAIN."

