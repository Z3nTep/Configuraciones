# 🛠️ Guía paso a paso: Despliegue de Jitsi Meet en AWS EKS con Kubernetes

## 🔑 Cosas previas a tener configuradas

Antes de comenzar con el despliegue de Jitsi Meet en AWS EKS, asegúrate de tener lo siguiente listo:

- **Zona hospedada en Route 53:**  
  Debes contar con una zona hospedada pública para el subdominio que vas a usar, por ejemplo:  
  - `sub.dominio.com`  
  Esto permitirá gestionar los registros DNS necesarios para el acceso externo a Jitsi Meet.

- **Certificado SSL para Jitsi:**  
  Es indispensable tener un certificado válido para el dominio completo que utilizará Jitsi Meet, por ejemplo:  
  - `jitsi.sub.dominio.com`  
  El certificado puede ser de ACM (AWS Certificate Manager) y debe estar en la misma región en la que desplegarás el clúster EKS.

- **Herramientas instaladas en tu máquina local:**  
  Asegúrate de tener instaladas y configuradas las siguientes herramientas de línea de comandos:
  - `aws-cli` (para interactuar con AWS)
  - `eksctl` (para crear y administrar clústeres de EKS)
  - `kubectl` (para gestionar recursos de Kubernetes)  
  Todas deben estar autenticadas y configuradas para operar sobre tu cuenta y región de AWS.

---

> **Sin estos requisitos previos, no podrás completar correctamente el despliegue de Jitsi Meet en AWS EKS.**

---

## 1. Lanza el clúster EKS

```
cat demo-eks-eksctl.yaml | envsubst | eksctl create cluster -f -
```

---

## 2. Instala Helm y Cert-Manager

```
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.14.4/cert-manager.yaml
```

**Espera a que cert-manager esté en estado Running:**

```
echo "Esperando a que cert-manager esté en estado Running..."
until kubectl get pods -n cert-manager 2>/dev/null | grep -E 'cert-manager|cainjector|webhook' | grep -q '1/1 *Running'; do
  sleep 15
  kubectl get pods -n cert-manager
done
```

---

## 3. Etiqueta las subredes públicas para el ALB

Puedes hacerlo de dos formas:

**A. Visual (tabla):**

| Key                                 | Value  | Descripción                                   |
|--------------------------------------|--------|-----------------------------------------------|
| kubernetes.io/role/elb               | 1      | Marca la subred como válida para ELB          |
| kubernetes.io/cluster/<cluster_name> | shared | Asocia la subred al clúster de Kubernetes     |

**B. Por comandos:**

```
aws ec2 create-tags --resources <subnet-id-1> <subnet-id-2> --tags Key=kubernetes.io/role/elb,Value=1 --region us-east-1
aws ec2 create-tags --resources <subnet-id-1> <subnet-id-2> --tags Key=kubernetes.io/cluster/<nombre-de-tu-cluster>,Value=shared --region us-east-1
```

> **Asegúrate de etiquetar correctamente las subredes públicas antes de instalar el AWS Load Balancer Controller para que pueda descubrirlas automáticamente[1][2].**

---

## 4. Instala AWS Load Balancer Controller

**Este paso es fundamental para que el Ingress de tipo ALB funcione correctamente en EKS.  
Debe hacerse después de etiquetar las subredes y de instalar el cert-manager.**

```
curl -Lo aws-load-balancer-controller.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.11.0/v2_11_0_full.yaml
sed -i "s/--cluster-name=.*/--cluster-name=$CLUSTER_NAME/" aws-load-balancer-controller.yaml
kubectl apply -f aws-load-balancer-controller.yaml
```

> **Revisión manual recomendada en el paso 4:**  
> Después de ejecutar el comando `sed` para modificar el fichero `aws-load-balancer-controller.yaml`, revisa manualmente que el cambio se haya aplicado correctamente.
>
> Para ello, abre el archivo y ve directamente a la línea 965, donde se encuentra la variable `--cluster-name=`.  
> Verifica que el valor corresponde al nombre de tu clúster EKS.
>
> Si el comando no funcionó correctamente, edita la línea manualmente para asegurarte de que el parámetro `--cluster-name=` tenga el valor adecuado.

Así es como debe verse la sección relevante del archivo `aws-load-balancer-controller.yaml` (línea 965 aprox.), con el valor correcto en `--cluster-name=`:

```
  template:
    metadata:
      labels:
        app.kubernetes.io/component: controller
        app.kubernetes.io/name: aws-load-balancer-controller
    spec:
      containers:
      - args:
        - --cluster-name=este-es-mi-cluster
        - --ingress-class=alb
        image: public.ecr.aws/eks/aws-load-balancer-controller:v2.11.0
        livenessProbe:
          failureThreshold: 2
          httpGet:
            path: /healthz
            port: 61779
            scheme: HTTP
          initialDelaySeconds: 30
```

Una vez que hayas verificado y, si es necesario, corregido la línea correspondiente, vuelve a aplicar el manifiesto con:

```
kubectl apply -f aws-load-balancer-controller.yaml
```

---

## 5. Aplica los manifiestos de Ingress y Cert Manager

```
kubectl apply -f alb-ingressclass.yml
kubectl apply -f ingress-issuer.yml 
```

---

## 6. Configura el StorageClass y el PVC para Prosody

```
kubectl delete storageclass gp2
kubectl apply -f prosody-pvc.yml
kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

---

## 7. Instala Jitsi Meet con Helm

```
helm repo add jitsi https://jitsi-contrib.github.io/jitsi-helm/
helm repo update
helm install myjitsi jitsi/jitsi-meet \
  --set ingress.enabled=true \
  --set ingress.annotations."kubernetes\.io/ingress\.class"=alb \
  --set ingress.hosts.host="jitsi.sub.dominio.com" \
  --set ingress.hosts.paths="/" \
  --set jvb.service.type=LoadBalancer \
  --set jvb.publicIPs="dominio.com" \
  --set publicURL="https://jitsi.sub.dominio.com"
```

---

## 8. Modifica los servicios para exponerlos como LoadBalancer

### 8.1 Edita los servicios

```
kubectl edit svc <nombre-del-svc>
```

---

### 8.2 Para el servicio de JVB

Añade la anotación:

```
service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
```

**Ejemplo de cómo debe verse:**

```
apiVersion: v1
kind: Service
metadata:
  annotations:
    meta.helm.sh/release-name: myjitsi
    meta.helm.sh/release-namespace: default
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
creationTimestamp: "2025-05-18T13:54:00Z"
labels:
  app.kubernetes.io/component: jvb
  app.kubernetes.io/instance: myjitsi
```

---

### 8.3 Para el servicio de Prosody

- Entra al servicio `myjitsi-prosody`:
  ```
  kubectl edit svc myjitsi-prosody
  ```
- Cambia `type: ClusterIP` por `type: LoadBalancer`.
- **Esto suele estar al final del documento (aprox. línea 55).**

**Ejemplo de cómo debe verse:**

```
targetPort: 5222
- name: tcp-xmpp-s2
  port: 5269
  protocol: TCP
  targetPort: 5269
selector:
  app.kubernetes.io/instance: myjitsi
  app.kubernetes.io/name: prosody
sessionAffinity: None
type: LoadBalancer
```

---

### 8.4 Para el servicio de Web

- Entra al servicio `myjitsi-jitsi-meet-web`:
  ```
  kubectl edit svc myjitsi-jitsi-meet-web
  ```
- Cambia `type: ClusterIP` por `type: LoadBalancer`.
- **Esto suele estar al final del documento (aprox. línea 41).**

**Ejemplo de cómo debe verse:**

```
targetPort: 80
selector:
  app.kubernetes.io/instance: myjitsi
  app.kubernetes.io/name: web
sessionAffinity: None
type: LoadBalancer
```

---

## 9. Verifica los servicios y obtén las IPs públicas

```
kubectl get svc
```

**Ejemplo de salida:**

```
NAME                        TYPE           CLUSTER-IP       EXTERNAL-IP                                                                    PORT(S)                                                                      AGE
cm-acme-http-solver-j6jd8   NodePort       10.100.232.44    <none>                                                                         8089:30453/TCP                                                               24m
kubernetes                  ClusterIP      10.100.0.1       <none>                                                                         443/TCP                                                                      55m
myjitsi-jitsi-meet-jvb      LoadBalancer   10.100.218.4     k8s-default-myjitsij-b8400397b5-f60c785b360fd9a2.elb.us-east-1.amazonaws.com   10000:30311/UDP                                                              93s
myjitsi-jitsi-meet-web      LoadBalancer   10.100.241.171   aec4cfb1087d84bf0b6dd5fa11804c60-1157458901.us-east-1.elb.amazonaws.com        80:31830/TCP                                                                 19m
myjitsi-prosody             LoadBalancer   10.100.247.80    a82a57385dc7a41eab3f0d01d240e84e-684857614.us-east-1.elb.amazonaws.com         5280:31022/TCP,5281:31705/TCP,5347:30474/TCP,5222:32752/TCP,5269:32668/TCP   19m
```

---

## 10. Obtén la URL del ALB y comprueba el Ingress

```
kubectl get pvc
kubectl get ingress
```


Así es como debería verse el resultado del comando `kubectl get ingress`:

```
NAME                        CLASS    HOSTS                   ADDRESS                                                                 PORTS     AGE
cm-acme-http-solver-bpksr   <none>   jitsi.sub.idumont.cat                                                                           80        150m
jitsi-web-ingress           alb      jitsi.sub.idumont.cat   k8s-default-jitsiweb-ca10227f9a-398667594.us-east-1.elb.amazonaws.com   80, 443   150m
```

Si no aparece el Ingress, ejecuta:

```
kubectl delete ingress jitsi-web-ingress
kubectl apply -f ingress.yml
kubectl get ingress jitsi-ingress
```

---

## 11. Crea el registro CNAME en Route53

- El registro debe ser un CNAME al ALB del Ingress.
- Ejemplo: `jitsi.sub.dominio.com` → `[ALB DNS]`

---

## 12. Solución rápida si te desconecta de la reunión al intentar unirte

```
kubectl get pods
kubectl delete pod myjitsi-prosody-0
kubectl delete pod -l app.kubernetes.io/component=jvb
```

---
---

## Felicidades, has terminado con la configuración.

