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

## Comprobar cuanto espacio ocupa docker

```
docker system df
```

Para limpiar todo lo que no esté en uso (imágenes huérfanas, contenedores detenidos y caché), puedes ejecutar el siguiente comando desde tu terminal:

```bash
docker system prune -a --volumes
```

> [!IMPORTANTE]
> **Ten en cuenta:** Esto borrará todas las imágenes que no estén siendo usadas por un contenedor activo en este momento. Si necesitas conservar alguna imagen específica que no esté corriendo, sáltate el `-a`.
