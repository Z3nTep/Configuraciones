# 🐋 Gestión de Entornos Docker

Este repositorio contiene la configuración y orquestación de diversos servicios mediante Docker, optimizados para un entorno bajo demanda y con un enfoque en la seguridad y el orden.

---

## 📂 Servicios Disponibles

| Servicio | Descripción |
| :--- | :--- |
| [**NextCloud**](./NextCloud) | Almacenamiento en la nube (openSUSE + MariaDB + Redis). |
| [**Windows**](./docker-windows) | Instancia de Windows con aceleración KVM. |
| [**VPN & AdBlock**](./VPN) | Túnel WireGuard con bloqueo de publicidad AdGuard Home. |
| [**Mine**](./Mine) | Servidor de Paper MC de alto rendimiento. |

---

## 🚀 Instalación Rápida

Para desplegar Docker en un sistema base Linux/WSL, ejecuta los siguientes comandos en orden:

### 1. Preparar el Entorno

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl software-properties-common
```

### 2. Instalar Docker Engine

```bash
sudo curl -fsSL https://get.docker.com/ | sh
```

---

## 🧹 Mantenimiento y Limpieza

Es fundamental monitorizar el uso de disco para evitar que los contenedores detengan su actividad.

### Comprobación de Uso

```bash
docker system df
```

### Limpieza de Recursos (Keep it Clean)

Este fichero elimina directorios temporales, imágenes huérfanas y contenedores detenidos que no se estén utilizando:

```bash
docker system prune -a --volumes
```

> [!WARNING]
> Ten en cuenta que el flag **-a** borrará todas las imágenes que no estén siendo usadas por un contenedor activo en este momento.

---

## 💾 Gestión de Espacio en WSL2 (.vhdx)

En entornos Windows con WSL2, los ficheros virtuales no recuperan el tamaño automáticamente tras borrar datos en Docker. Sigue este método según tu versión:

| Versión de Windows | Método | Tipo de Gestión |
| :--- | :--- | :--- |
| **Windows 11** | `wsl --set-sparse` | ✅ Automático |
| **Windows 10** | `diskpart` (compact) | ⚠️ Manual |

---

## 🟦 Solución para Windows 11 (Automático)

Windows 11 permite habilitar una función para que el disco se encoja automáticamente sin tener que hacer nada más.

```powershell
# 1. Apaga WSL primero
wsl --shutdown

# 2. Activa el modo sparse (Cambia 'Ubuntu' por el nombre de tu distro)
wsl --manage <Tu_Distro> --set-sparse true
```

---

## 🟦 Solución para Windows 10 (Manual)

En Windows 10, debes compactar el disco manualmente cada vez que necesites recuperar espacio.

### 1. Preparación

Cierra WSL y abre la utilidad de discos en una terminal de PowerShell **como Administrador**:

```powershell
wsl --shutdown
diskpart
```

### 2. Comandos en Diskpart

Una vez dentro de la utilidad `diskpart`, ejecuta la siguiente secuencia:

```powershell
# Selecciona el fichero VHDX
select vdisk file="C:\Users\TU_USUARIO\AppData\Local\Packages\...\LocalState\ext4.vhdx"

# Proceso de compactación
compact vdisk

# Salir de la utilidad
exit
```

> [!TIP]
> **¿No conoces la ruta?** Ejecuta esto en PowerShell para ver la ruta exacta:
> `Get-ChildItem -Path "$env:LOCALAPPDATA\Packages" -Filter "ext4.vhdx" -Recurse | Select-Object -ExpandProperty FullName`
