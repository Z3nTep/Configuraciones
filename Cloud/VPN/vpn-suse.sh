#!/bin/bash

# Actualizar e instalar los paquetes necesarios
sudo zypper refresh
sudo zypper install -y wireguard-tools iptables

# Crear directorio y claves de WireGuard
sudo mkdir -p /etc/wireguard
wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
SERVER_PRIVATE_KEY=$(cat /etc/wireguard/server_private.key)

# Configuración de WireGuard
cat <<EOF | sudo tee /etc/wireguard/wg0.conf
[Interface]
Address = 5.0.0.0/31
PrivateKey = $SERVER_PRIVATE_KEY
ListenPort = 55555
SaveConfig = true

[Peer]
PublicKey = CLIENT_PUBLIC_KEY
AllowedIPs = 5.0.0.1/31
EOF

# Habilitar reenvío de IP y configurar WireGuard
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
sudo systemctl start wg-quick@wg0
sudo systemctl enable wg-quick@wg0

# Configurar firewall
sudo firewall-cmd --permanent --add-port=55555/udp
sudo firewall-cmd --reload

# Configurar NAT y redirección de puertos
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -t nat -A PREROUTING -p tcp --dport 55555 -j DNAT --to-destination 5.0.0.1:443
sudo iptables -A FORWARD -p tcp -d 5.0.0.1 --dport 443 -j ACCEPT

# Guardar configuración de iptables
sudo iptables-save | sudo tee /etc/iptables/rules.v4

echo "Configuración completada."
