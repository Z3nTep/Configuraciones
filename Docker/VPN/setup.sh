#!/bin/bash
# Crear estructura de directorios
echo "Creando estructura de directorios..."
mkdir -p ~/z3ndns/wireguard/config
mkdir -p ~/z3ndns/adguard/{conf,work}
mkdir -p ~/z3ndns/nginx/{config,web-sites}

# Crear archivo de bienvenida para la web
echo "Configurando página web..."
cat > ~/z3ndns/nginx/web-sites/index.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Z3nDNS</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background-color: #f5f5f5;
        }
        .container {
            text-align: center;
            padding: 2rem;
            border-radius: 10px;
            background-color: white;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2c3e50;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Bienvenido a mi página</h1>
        <p>Tu solución VPN con bloqueo de anuncios está funcionando correctamente.</p>
    </div>
</body>
</html>
EOF

# Configurar Nginx
echo "Configurando Nginx..."
cat > ~/z3ndns/nginx/config/default.conf << 'EOF'
server {
    listen 80;
    server_name tu.dominio.com;
    
    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
}
EOF

# Copiar archivos de configuración
echo "Copiando archivos de configuración..."
cp docker-compose.yml ~/z3ndns/
cp .env ~/z3ndns/

# Crear script para actualizar configuración WireGuard
echo "Creando script para configuración de WireGuard..."
cat > ~/z3ndns/configure-wireguard.sh << 'EOF'
#!/bin/bash

# Esperar a que los contenedores estén en funcionamiento
echo "Esperando a que los servicios estén en línea..."
sleep 15

echo "Configurando WireGuard..."
cd ~/z3ndns

# Asegurarse de que WireGuard use AdGuard como DNS
source .env
docker-compose restart wireguard

echo "Configuración completada."
echo ""
echo "Los archivos de configuración para tus clientes están en:"
echo "~/z3ndns/wireguard/config/peer1/"
echo "~/z3ndns/wireguard/config/peer2/"
echo "~/z3ndns/wireguard/config/peer3/"
echo ""
echo "Puedes ver los códigos QR con: docker exec -it wireguard /app/show-peer <número>"
echo "Ejemplo: docker exec -it wireguard /app/show-peer 1"
EOF

chmod +x ~/z3ndns/configure-wireguard.sh

echo "Instalación completada."
echo ""
echo "Para iniciar los servicios, ejecuta:"
echo "cd ~/z3ndns && docker-compose up -d"
echo ""
echo "Después, ejecuta el script de configuración:"
echo "~/z3ndns/configure-wireguard.sh"
echo ""
echo "No olvides actualizar tu token en el script update-duckdns.sh"
echo "y programar una tarea cron para mantener actualizada tu IP pública."