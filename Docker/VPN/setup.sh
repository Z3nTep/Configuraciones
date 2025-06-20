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

echo "Puedes ver los códigos QR con: docker exec -it wireguard /app/show-peer <número>"
echo "Ejemplo: docker exec -it wireguard /app/show-peer 1" 
