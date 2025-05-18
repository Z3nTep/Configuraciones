# 🛠️ Guía paso a paso: Despliegue de FreePBX en AWS EKS con Kubernetes

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

---

## 4. Instala AWS Load Balancer Controller

> **Este paso es fundamental para que el Ingress de tipo ALB funcione correctamente en EKS.  
> Debe hacerse después de etiquetar las subredes y de instalar el cert-manager.**

```
curl -Lo aws-load-balancer-controller.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.11.0/v2_11_0_full.yaml
sed -i "s/--cluster-name=.*/--cluster-name=$CLUSTER_NAME/" aws-load-balancer-controller.yaml
kubectl apply -f aws-load-balancer-controller.yaml
```

---

## 5. Aplica los manifiestos de Ingress y Cert Manager

```
kubectl apply -f ingress-issuer.yml 
kubectl apply -f alb-ingressclass.yml
```

---

## 6. Configura el StorageClass y el PVC para FreePBX

```
kubectl delete storageclass gp2
kubectl apply -f freepbx-pvc.yml
kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

---

## 7. Despliega FreePBX

```
kubectl apply -f freepbx-deployment.yml
```

---

## 8. Obtén la URL del Load Balancer

```
kubectl get svc
```

### Ejemplo de salida esperada

```
NAME                        TYPE           CLUSTER-IP      EXTERNAL-IP                                                                   PORT(S)                                                                      AGE
cm-acme-http-solver-6s2p2   NodePort       10.100.92.146   <none>                                                                        8089:30534/TCP                                                               74m
freepbx                     LoadBalancer   10.100.42.33    k8s-default-freepbx-e186ddcffd-4043bbcbef2cfa82.elb.us-east-1.amazonaws.com   80:32120/TCP,5060:31187/UDP,5160:30537/UDP,18000:30535/UDP,18001:31439/UDP   60m
kubernetes                  ClusterIP      10.100.0.1      <none>                                                                        443/TCP                                                                      87m
```

El valor de la columna `EXTERNAL-IP` para el servicio `freepbx` es el nombre DNS del Load Balancer:

```
k8s-default-freepbx-e186ddcffd-4043bbcbef2cfa82.elb.us-east-1.amazonaws.com
```

---

## 9. Crea el registro CNAME en Route53

- Ve a la consola de Route53.
- Crea un registro CNAME apuntando tu subdominio (por ejemplo, `freepbx.sub.dominio.com`) al nombre DNS del Load Balancer que obtuviste en el paso anterior.

**Ejemplo:**

```
freepbx.sub.dominio.com   CNAME   k8s-default-freepbx-e186ddcffd-4043bbcbef2cfa82.elb.us-east-1.amazonaws.com
```

---

## 10. Accede a FreePBX usando tu dominio personalizado

> **IMPORTANTE:**  
> - Debes acceder al panel de administración en  
>   ```
>   http://freepbx.sub.dominio.com/admin
>   ```
>   *(No solo a la raíz, sino añadiendo `/admin` al final de la URL).*
>
> - **La primera carga puede tardar entre 5 y 10 minutos** después de hacer el `kubectl apply -f freepbx-deployment.yml`, especialmente en la instalación inicial.  
>   Ten paciencia y espera a que la interfaz esté disponible antes de intentar acceder de nuevo.

---

## 11. (Opcional) Solución rápida para reiniciar FreePBX si tienes problemas

```
kubectl get pods
kubectl delete pod <nombre-del-pod-de-freepbx>
```
