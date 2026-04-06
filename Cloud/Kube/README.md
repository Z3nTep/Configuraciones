# ☸️ Recursos de Kubernetes (K8s)

Este directorio contiene referencias y comandos esenciales para la gestión de clústeres de Kubernetes, con un enfoque en despliegues sobre EKS y pruebas con Podinfo.

---

## 🔗 Recursos y Referencias

| Origen | Enlace / Comentario |
| :--- | :--- |
| **K8s-Eks (Pardos)** | [Repositorio GitHub](https://github.com/santos-pardos/K8s-Eks/tree/main) |
| **Podinfo (Stefan Prodan)** | [Repositorio GitHub](https://github.com/stefanprodan/podinfo) |

> [!TIP]
> La imagen recomendada es `stefanprodan/podinfo`. Se sugiere sustituir la imagen por defecto en los despliegues de Pardos.

---

## 🛠️ Comandos Útiles (kubectl)

### Consultas Rápidas
| Acción | Comando |
| :--- | :--- |
| Ver todos los Pods | `kubectl get pods` |
| Ver despliegues | `kubectl get deployments` |
| Ver todos los recursos | `kubectl get all` |

### Gestión de Ficheros
| Acción | Comando |
| :--- | :--- |
| Desplegar configuración | `kubectl apply -f fichero.yml` |
| Editar configuración | `kubectl edit -f fichero.yml` |
| Eliminar configuración | `kubectl delete -f fichero.yml` |
