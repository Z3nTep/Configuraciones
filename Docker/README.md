# Para instalar docker seguir estos comandos:

## 1. Actualizamos los repositorios:

```
sudo apt-get update
sudo apt-get install -y ca-certificates curl software-properties-common
```

---

## 2. Instalamos DockerV2:

```
sudo curl -fsSL https://get.docker.com/ | sh
```


---
---

# Comprobar cuanto espacio ocupa docker

```
docker system df
```

Para limpiar todo lo que no esté en uso (imágenes huérfanas, contenedores detenidos y caché), puedes ejecutar el siguiente comando desde tu terminal:

```bash
docker system prune -a --volumes
```

> [!IMPORTANTE]
> **Ten en cuenta:** Esto borrará todas las imágenes que no estén siendo usadas por un contenedor activo en este momento. Si necesitas conservar alguna imagen específica que no esté corriendo, sáltate el `-a`.

---
---

# 🔧 Guía: Reclamar Espacio de Disco en WSL2 (.vhdx)

Si borras archivos en WSL2 (como imágenes de Docker), el archivo virtual (`.vhdx`) en Windows no se encoge solo. Aquí tienes cómo solucionarlo dependiendo de tu versión de Windows:

| Versión | Método | ¿Es automático? |
| :--- | :--- | :--- |
| **Windows 10** | `diskpart` -> `compact vdisk` | No (Manual) |
| **Windows 11** | `wsl --set-sparse true` | Sí (Automático) |

---

## 🟦 Para Windows 10 (Método Manual)

En Windows 10, debes compactar el disco manualmente cada vez que necesites recuperar espacio.

### Paso 1: Cerrar WSL
Abre una terminal de PowerShell y ejecuta:
```powershell
wsl --shutdown
```

### Paso 2: Usar Diskpart (Como Administrador)
Abre PowerShell **como Administrador** y entra en la utilidad de discos:
```powershell
diskpart
```

### Paso 3: Comandos de Compactación
Dentro de `diskpart`, ejecuta estas líneas (cambia la ruta por la tuya):
```powershell
# 1. Selecciona el archivo VHDX
select vdisk file="C:\Users\TU_USUARIO\AppData\Local\Packages\...\LocalState\ext4.vhdx"

# 2. Compáctalo
compact vdisk

# 3. Salir
exit
```

> [!TIP]
> **¿Cómo encontrar mi ruta?** Ejecuta esto en PowerShell para ver la ruta exacta:
> `Get-ChildItem -Path "$env:LOCALAPPDATA\Packages" -Filter "ext4.vhdx" -Recurse | Select-Object -ExpandProperty FullName`

---

## 🟦 Para Windows 11 (Método Automático)

Windows 11 permite habilitar una función para que el disco se encoja automáticamente sin tener que hacer nada más.

### Configurar el modo "Sparse"
Abre una terminal de PowerShell y ejecuta:
```powershell
# 1. Apaga WSL primero
wsl --shutdown

# 2. Activa el modo sparse (Cambia 'Ubuntu' por el nombre de tu distro)
wsl --manage Ubuntu --set-sparse true
```
