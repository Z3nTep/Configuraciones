# Parches
# ------------------------------   Borrar cosas   ----------------------------------------------------

# Borrar todo
kubectl delete pods --all
kubectl delete deployment --all
kubectl delete statefulset --all
kubectl delete svc --all
kubectl delete ingress --all

# Problemas del svc
# Ver PVC y PV
kubectl get pvc
kubectl get pv

# Eliminar normalmente
kubectl delete pvc <nombre-del-pvc>

# Si se queda en Terminating, forzar quitando el finalizer
kubectl patch pvc <nombre-del-pvc> -p '{"metadata":{"finalizers":null}}'

# Si el PV asociado también se queda en Terminating, forzar su borrado igual
kubectl patch pv <nombre-del-pv> -p '{"metadata":{"finalizers":null}}'

# -----------------------------   Problemas con la VPC   ---------------------------------------------

# Listar subredes de la VPC por defecto
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>" --region us-east-1 --query "Subnets[*].{ID:SubnetId,AZ:AvailabilityZone,Tags:Tags}"

# Añadir el tag necesario para LoadBalancer público a cada subnet pública
aws ec2 create-tags --resources <subnet-id-1> <subnet-id-2> --tags Key=kubernetes.io/role/elb,Value=1 --region us-east-1

# (Opcional pero recomendado) Añadir el tag del clúster a cada subnet pública
aws ec2 create-tags --resources <subnet-id-1> <subnet-id-2> --tags Key=kubernetes.io/cluster/<nombre-de-tu-cluster>,Value=shared --region us-east-1


# Esperar unos minutos a que Kubernetes detecte los tags y cree el LoadBalancer
# Si no aparece la EXTERNAL-IP, eliminar y recrear el servicio:
kubectl delete svc <nombre-del-svc-que-use-lb>  # Con jitsi se llama myjitsi-jitsi-meet-jvb (el que sale en pending en EXTERNAL-IP)

helm upgrade ... # (tu comando de helm para recrear el servicio)

# Verificar que el servicio ya tiene EXTERNAL-IP
kubectl get svc

# ----------------------------    Modificaciones de los .yml de jitsi   ----------------------------

# Para editar los .yml con helm
kubectl edit svc <nombre-del-svc>

# Para el jitsi, entrar al jitsi-meet-jvc y añadir el LB publico. Aquí enseño donde va:
apiVersion: v1
kind: Service
metadata:
  annotations:
    meta.helm.sh/release-name: myjitsi
    meta.helm.sh/release-namespace: default
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"

# Para el prosody, entrar al jitsi-prosody, cambiar type: ClusterIP por LoadBalancer
# Para el web, entrar al jisti-meet-web y hacer lo mismo que el prosody
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
  
# Para solucionar el problema del pvc hay que hacer apply del prosody-pvc.yml
kubectl delete storageclass gp2
kubectl apply -f prosody-pvc.yml
# Y ponerlo como por defecto.
kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

  
# ----------------------------   Ingress   ------------------------------------------------------

# Puto Ingress
kubectl delete ingress jitsi-web-ingress
kubectl apply -f ingress.yml
kubectl get ingress jitsi-ingress

kubectl delete clusterissuer letsencrypt-http01
kubectl apply -f clusterissuer.yml 

# ----------------------------   Problemas con el cluster   ------------------------------------

# Escalar pods para solucionar problemas como
	# 0/1 nodes are available: 1 Too many pods. preemption: 0/1 nodes are available: 1 No preemption victims found for incoming pod.
eksctl scale nodegroup --cluster <nombre-del-cluster> --name <nombre-del-node-group> --nodes 2

# ----------------------------   Guia   --------------------------------------------------------

# Lanzas el cluster
cat demo-eks-eksctl.yaml | envsubst | eksctl create cluster -f -

# Crea los .yml alb-ingressclass, ingress-ussuer y haz los apply
kubectl apply -f ingress-issuer.yml 
kubectl apply -f alb-ingressclass.yml

# Instalar AWS Load Balancer Controller
curl -Lo aws-load-balancer-controller.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.11.0/v2_11_0_full.yaml
sed -i "s/--cluster-name=.*/--cluster-name=$CLUSTER_NAME/" aws-load-balancer-controller.yaml
kubectl apply -f aws-load-balancer-controller.yaml

# Ahora borramos el storageclass existente y creamos el nuestro, depsues lo ponemos por defecto
kubectl delete storageclass gp2
kubectl apply -f prosody-pvc.yml
kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Instalamos helm y el cert-manager
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.14.4/cert-manager.yaml
echo "Esperando a que cert-manager esté en estado Running..."
until kubectl get pods -n cert-manager 2>/dev/null | grep -E 'cert-manager|cainjector|webhook' | grep -q '1/1 *Running'; do
  sleep 15
  kubectl get pods -n cert-manager
done

# Ahora tenemos que añadir estos tag a las dos subredes publicas que queramos usar:
# En mi caso usaré la 1a y 1b de la VPC default.
echo "Key:										Value:	"
echo "kubernetes.io/role/elb						1	"
# Por comandos es:
aws ec2 create-tags --resources <subnet-id-1> <subnet-id-2> --tags Key=kubernetes.io/role/elb,Value=1 --region us-east-1
aws ec2 create-tags --resources <subnet-id-1> <subnet-id-2> --tags Key=kubernetes.io/cluster/<nombre-de-tu-cluster>,Value=shared --region us-east-1

# Seguidamente creamos el jitsi:
helm repo add jitsi https://jitsi-contrib.github.io/jitsi-helm/
helm repo update
helm install myjitsi jitsi/jitsi-meet \
  --set ingress.enabled=true \
  --set ingress.annotations."kubernetes\.io/ingress\.class"=alb \
  --set ingress.hosts[0].host="jitsi.sub.idumont.cat" \
  --set ingress.hosts[0].paths[0]="/" \
  --set jvb.service.type=LoadBalancer \
  --set jvb.publicIPs[0]="idumont.cat" \
  --set publicURL="https://jitsi.sub.idumont.cat"
  
# Para continuar, modificamos los siguientes ficheros del jitsi para indicar que usen un LoadBalancer
# 	Para editar los .yml con helm
kubectl edit svc <nombre-del-svc>

# 	Eentrar al jitsi-meet-jvc y añadir esta línea 
# 		service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
# 	Aquí enseño donde va:
	apiVersion: v1
	kind: Service
	metadata:
	  annotations:
		meta.helm.sh/release-name: myjitsi
		meta.helm.sh/release-namespace: default
		service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"	# Aquí está
	creationTimestamp: "2025-05-18T13:54:00Z"
	labels:
		app.kubernetes.io/component: jvb
		app.kubernetes.io/instance: myjitsi

# 	Para el prosody, entrar al jitsi-prosody, cambiar type: ClusterIP por LoadBalancer
# 	Para el web, entrar al jisti-meet-web y hacer lo mismo que el prosody
#		La línea es la 55 y 41, al final del documento
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

# Para asegurarnos de que todo esta bien hacemos:
kubectl get svc
echo "NAME                        TYPE           CLUSTER-IP       EXTERNAL-IP                                                                    PORT(S)                                                                      AGE"
echo "cm-acme-http-solver-j6jd8   NodePort       10.100.232.44    <none>                                                                         8089:30453/TCP                                                               24m"
echo "kubernetes                  ClusterIP      10.100.0.1       <none>                                                                         443/TCP                                                                      55m"
echo "myjitsi-jitsi-meet-jvb      LoadBalancer   10.100.218.4     k8s-default-myjitsij-b8400397b5-f60c785b360fd9a2.elb.us-east-1.amazonaws.com   10000:30311/UDP                                                              93s"
echo "myjitsi-jitsi-meet-web      LoadBalancer   10.100.241.171   aec4cfb1087d84bf0b6dd5fa11804c60-1157458901.us-east-1.elb.amazonaws.com        80:31830/TCP                                                                 19m"
echo "myjitsi-prosody             LoadBalancer   10.100.247.80    a82a57385dc7a41eab3f0d01d240e84e-684857614.us-east-1.elb.amazonaws.com         5280:31022/TCP,5281:31705/TCP,5347:30474/TCP,5222:32752/TCP,5269:32668/TCP   19m"

# Pillamos la url del ALB
kubectl get pvc
# En caso de que no aparezca nada hacer los siguientes comandos:
kubectl delete ingress jitsi-web-ingress
kubectl apply -f ingress.yml
kubectl get ingress jitsi-ingress

# Creamos el CNAME en route53
echo "En mi caso lo llamaré jitsi.sub.idumont.cat y el registro debe ser un cname al ALB del ingress"


# En caso de que desconecte de la reunión cuando intentes unirte haz esto:
kubectl get pods
kubectl delete pod myjitsi-prosody-0
kubectl delete pod -l app.kubernetes.io/component=jvb


# ----------------------------   Si todo esta correcto   ---------------------------------------

# Como se ve cuando todo funciona
# Todos los pods de jitsi estan running
ubuntu@ip-172-31-85-17:~/eks/jitsi$ kubectl get pods
NAME                                         READY   STATUS    RESTARTS   AGE
cm-acme-http-solver-fzmlt                    1/1     Running   0          29m
myjitsi-jitsi-meet-jicofo-847d6f9695-5xmvr   1/1     Running   0          9m31s
myjitsi-jitsi-meet-jvb-56d877fd78-pnzzk      1/1     Running   0          9m31s
myjitsi-jitsi-meet-web-6c9784b6cb-hkj6k      1/1     Running   0          30m
myjitsi-prosody-0                            1/1     Running   0          9m31s

# Los services:
ubuntu@ip-172-31-84-193:~/jitsi$ kubectl get svc
NAME                        TYPE           CLUSTER-IP       EXTERNAL-IP                                                                    PORT(S)                                                                      AGE
cm-acme-http-solver-j6jd8   NodePort       10.100.232.44    <none>                                                                         8089:30453/TCP                                                               24m
kubernetes                  ClusterIP      10.100.0.1       <none>                                                                         443/TCP                                                                      55m
myjitsi-jitsi-meet-jvb      LoadBalancer   10.100.218.4     k8s-default-myjitsij-b8400397b5-f60c785b360fd9a2.elb.us-east-1.amazonaws.com   10000:30311/UDP                                                              93s
myjitsi-jitsi-meet-web      LoadBalancer   10.100.241.171   aec4cfb1087d84bf0b6dd5fa11804c60-1157458901.us-east-1.elb.amazonaws.com        80:31830/TCP                                                                 19m
myjitsi-prosody             LoadBalancer   10.100.247.80    a82a57385dc7a41eab3f0d01d240e84e-684857614.us-east-1.elb.amazonaws.com         5280:31022/TCP,5281:31705/TCP,5347:30474/TCP,5222:32752/TCP,5269:32668/TCP   19m

# El pvc asi:
ubuntu@ip-172-31-85-17:~/eks/jitsi$ kubectl get pvc
NAME                             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
prosody-data-myjitsi-prosody-0   Bound    pvc-8bea15e0-860c-4af4-9b65-6b9cff47d6af   3Gi        RWO            gp2            <unset>                 9m44s

# El ingress
ubuntu@ip-172-31-85-17:~/eks/jitsi$ kubectl get ingress
NAME                        CLASS    HOSTS                   ADDRESS                                                                 PORTS     AGE
cm-acme-http-solver-bpksr   <none>   jitsi.sub.idumont.cat                                                                           80        150m
jitsi-web-ingress           alb      jitsi.sub.idumont.cat   k8s-default-jitsiweb-ca10227f9a-398667594.us-east-1.elb.amazonaws.com   80, 443   150m
# Hay que pillar la url y ponerla como cname en el route53 o en el cloudflare, donde se tenga el registro