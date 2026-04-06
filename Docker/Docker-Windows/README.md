# 🏁 Windows en Docker (dockurr/windows)

Este proyecto permite ejecutar una instancia de Windows (desde la versión 3.1 hasta Windows 11) dentro de un contenedor Docker de forma nativa e integrada.

---

## ⚠️ Requisito Obligatorio: KVM

Para que el contenedor pueda iniciar, es **OBLIGATORIO** contar con soporte para KVM (Virtualización por Hardware). Sin este requisito, el despliegue no es posible.

### Tabla de Compatibilidad

| Sistema Operativo | Soporta KVM | Nota |
| :--- | :---: | :--- |
| **Windows 11 + WSL2** | ✅ Sí | Soportado de forma nativa. |
| **Linux** | ✅ Sí | Soportado de forma nativa. |
| **Windows 10 + WSL2** | ❌ No | No ofrece compatibilidad. |

---

## 🛠️ Variables de Configuración

Puedes ajustar el comportamiento del contenedor modificando el fichero `docker-compose.yml` o creando un fichero `.env` en el mismo directorio:

| Variable | Descripción |
| :--- | :--- |
| `VERSION` | Versión de Windows a instalar (ej: `win11`, `win10`). |
| `RAM_SIZE` | Cantidad de memoria RAM asignada (ej: `8G`). |
| `CPU_CORES` | Número de núcleos de CPU dedicados (ej: `4`). |
| `DISK_SIZE` | Tamaño del disco duro virtual (ej: `64G`). |
| `ARGUMENTS` | Argumentos adicionales de QEMU. |
| `TPM` | Activa el chip TPM (obligatorio para Windows 11). |

---

## 🚀 Cómo empezar

1. **Verificación**: Comprueba la existencia del fichero de dispositivo ejecutando el siguiente comando en tu terminal:

   ```bash
   ls /dev/kvm
   ```

2. **Despliegue**: Inicia el contenedor desde el directorio del proyecto:

   ```bash
   docker-compose up -d
   ```

---

## 📝 Notas de Uso

* El primer arranque descargará el fichero ISO oficial directamente desde los servidores de Microsoft.
* Todos los datos persistentes se almacenan en el directorio `./win-data/`.
* Para más información, consulta el repositorio oficial: [dockur/windows](https://github.com/dockur/windows)
