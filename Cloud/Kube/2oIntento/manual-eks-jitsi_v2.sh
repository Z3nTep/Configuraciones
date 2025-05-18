# Variables (ajusta según tu entorno)
CLUSTER_NAME=demo-cluster-002
REGION=us-east-1
NODEGROUP_NAME=demo-worker-002
NODE_TYPE=t3.medium
NODES=2

# 1. Crear NodeGroup si no hay nodos
if [ "$(kubectl get nodes --no-headers 2>/dev/null | wc -l)" -eq 0 ]; then
  echo "No hay nodos en el clúster. Creando NodeGroup..."
  eksctl create nodegroup \
    --cluster $CLUSTER_NAME \
    --region $REGION \
    --name $NODEGROUP_NAME \
    --node-type $NODE_TYPE \
    --nodes $NODES \
    --nodes-min 1 \
    --nodes-max 3 \
    --managed
else
  echo "Ya hay nodos en el clúster."
fi

# 2. Esperar a que los nodos estén listos
echo "Esperando a que los nodos estén en estado Ready..."
until kubectl get nodes | grep -q ' Ready '; do
  sleep 5
  kubectl get nodes
done

# 3. Instalar Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 4. Instalar cert-manager
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.14.4/cert-manager.yaml

# 5. Esperar a que cert-manager esté listo
echo "Esperando a que cert-manager esté en estado Running..."
until kubectl get pods -n cert-manager 2>/dev/null | grep -E 'cert-manager|cainjector|webhook' | grep -q '1/1 *Running'; do
  sleep 15
  kubectl get pods -n cert-manager
done

# 6. Instalar AWS Load Balancer Controller
curl -Lo aws-load-balancer-controller.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.11.0/v2_11_0_full.yaml
sed -i "s/--cluster-name=.*/--cluster-name=$CLUSTER_NAME/" aws-load-balancer-controller.yaml
kubectl apply -f aws-load-balancer-controller.yaml

# 7. Instalar Jitsi con Helm
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

kubectl get ingress
