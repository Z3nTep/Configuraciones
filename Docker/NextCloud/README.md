# Nextcloud All-in-One (openSUSE)

Entorno completo de Nextcloud basado en **openSUSE Leap 15.5** usando Docker Compose.

---

## 🗺️ Estructura de Directorios

```text
.
├── nc-data/
│   ├── app/            # Datos de Nextcloud
│   ├── data/           # Datos subidos por los usuarios
│   ├── db/             # Datos de la BBDD (MariaDB)
│   └── redis/          # Caché persistente
├── Dockerfile          
├── entrypoint.sh       
├── docker-compose.yml
└── .env
```

---

## ⚙️ Variables de Entorno (`.env`)

* `HOST_PORT`: Puerto de acceso en el host (ej. `8080`).
* `MYSQL_ROOT_PASSWORD`: Contraseña root de MariaDB.
* `MYSQL_DATABASE`: Nombre de la base de datos (por defecto: `nextcloud`).
* `MYSQL_USER`: Usuario de la base de datos.
* `MYSQL_PASSWORD`: Contraseña de la base de datos.
* `REDIS_HOST_PASSWORD`: Contraseña para Redis.

> [!TIP]
> Si usas base de datos externa, elimina el servicio `db` de `docker-compose.yml`.

---

## 🚀 Instalación y Arranque

1. Configura las contraseñas en `.env`.
2. Ejecuta lo siguiente desde el directorio del proyecto:

```bash
docker-compose up -d --build
```

1. Accede a `http://localhost:8080` en tu navegador.
2. Configura el primer usuario administrador.
3. Configura la conexión de Base de Datos:

* Usuario: `nextcloud` (o tu variable `MYSQL_USER`).
* Contraseña: La misma de `MYSQL_PASSWORD`.
* Base de datos: `nextcloud`.
* Host: `db`.
