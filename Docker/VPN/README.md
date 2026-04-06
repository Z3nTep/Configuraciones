# 🛡️ VPN & AdBlock (WireGuard + AdGuard Home)

Este proyecto despliega una red privada virtual (VPN) securizada y un servidor DNS con bloqueo de publicidad integrado.

---

### Mapa de Directorios

```text
.
├── adguard/
│   ├── conf/       # Configuración de AdGuard Home
│   └── work/       # Datos de trabajo de AdGuard Home
├── wireguard/
│   └── config/     # Configuración y perfiles de WireGuard
└── docker-compose.yml
```

---

## ⚠️ Requisito en el Host (iptables)

Para habilitar el enrutamiento del tráfico desde la VPN, es **obligatorio** ejecutar el siguiente comando en el sistema host:

```bash
sudo iptables -t nat -A POSTROUTING -s 55.0.0.0/24 -o enp0s6 -j MASQUERADE
```

---

## 🚀 Despliegue

1. Inicia los servicios desde el directorio del proyecto:
   ```bash
   docker-compose up -d
   ```
2. Accede al panel de control de AdGuard Home:
   * **Instalación**: Puerto `3000`.
   * **Panel Principal**: Puerto `8081`.
3. Los ficheros de configuración para los clientes de WireGuard se generan automáticamente en el directorio `./wireguard/config/`.

---

## 🔗 Enlaces de interés

*   **WireGuard (LinuxServer)**: [linuxserver/wireguard](https://github.com/linuxserver/docker-wireguard)
*   **AdGuard Home**: [adguard/adguardhome](https://github.com/AdguardTeam/AdGuardHome)
