#!/bin/bash

# ==============================
# CONFIGURACIÓN
# ==============================
NOM_CLUSTER=${NOM_CLUSTER:-demo-cluster-002}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_DEFAULT_REGION:-us-east-1}
WP_NAMESPACE="wordpress"
WP_DB_PASSWORD="W0rdPr3ssP@ss123!"

if [ -z "$AWS_ACCOUNT_ID" ]; then
  echo "❌ No se pudo obtener AWS_ACCOUNT_ID"
  exit 1
fi

# ==============================
# CREAR ESTRUCTURA
# ==============================
DIR="$WP_NAMESPACE"
mkdir -p ${DIR}/{secrets,pvc,deployments,services}

# ==============================
# 1. NAMESPACE
# ==============================
cat > ${DIR}/namespace.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${WP_NAMESPACE}
EOF

# ==============================
# 2. SECRET
# ==============================
cat > ${DIR}/secrets/mysql-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: mysql-pass
  namespace: wordpress
type: Opaque
data:
  password: $(echo -n "$WP_DB_PASSWORD" | base64)
EOF

# ==============================
# 3. PVCs
# ==============================
for pvc in mysql wp; do
cat > ${DIR}/pvc/${pvc}-pvc.yaml <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${pvc}-pv-claim
  namespace: ${WP_NAMESPACE}
  labels:
    app: ${WP_NAMESPACE}
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp2
  resources:
    requests:
      storage: 20Gi
EOF
done

# ==============================
# 4. DEPLOYMENTS
# ==============================
# MySQL
cat > ${DIR}/deployments/mysql-deploy.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: ${WP_NAMESPACE}
  labels:
    app: ${WP_NAMESPACE}
spec:
  selector:
    matchLabels:
      app: ${WP_NAMESPACE}
      tier: mysql
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: ${WP_NAMESPACE}
        tier: mysql
    spec:
      containers:
      - image: mysql:8.0
        name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-pass
              key: password
        - name: MYSQL_DATABASE
          value: wordpress
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mysql-persistent-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-persistent-storage
        persistentVolumeClaim:
          claimName: mysql-pv-claim
EOF

# WordPress
cat > ${DIR}/deployments/wordpress-deploy.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  namespace: ${WP_NAMESPACE}
  labels:
    app: ${WP_NAMESPACE}
spec:
  selector:
    matchLabels:
      app: ${WP_NAMESPACE}
      tier: frontend
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: ${WP_NAMESPACE}
        tier: frontend
    spec:
      containers:
      - image: wordpress:6.5-php8.2-apache
        name: wordpress
        env:
        - name: WORDPRESS_DB_HOST
          value: mysql
        - name: WORDPRESS_DB_USER
          value: root
        - name: WORDPRESS_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-pass
              key: password
        - name: WORDPRESS_DB_NAME
          value: wordpress
        ports:
        - containerPort: 80
        volumeMounts:
        - name: wordpress-persistent-storage
          mountPath: /var/www/html
      volumes:
      - name: wordpress-persistent-storage
        persistentVolumeClaim:
          claimName: wp-pv-claim
EOF

# ==============================
# 5. SERVICES
# ==============================
cat > ${DIR}/services/mysql-svc.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: ${WP_NAMESPACE}
spec:
  ports:
    - port: 3306
  selector:
    app: ${WP_NAMESPACE}
    tier: mysql
  clusterIP: None
EOF

# ✅ SERVICIO DE WORDPRESS CON NLB
cat > ${DIR}/services/wordpress-svc.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: wordpress
  namespace: ${WP_NAMESPACE}
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: ${WP_NAMESPACE}
    tier: frontend
EOF

# ==============================
# 6. SCRIPT DE DESPLIEGUE
# ==============================
cat > ${DIR}/deploy.sh <<'EOF'
#!/bin/bash
echo "🌐 Aplicando WordPress con NLB..."
kubectl apply -f namespace.yaml
kubectl apply -f secrets/
kubectl apply -f pvc/
kubectl apply -f deployments/
kubectl apply -f services/

echo ""
echo "✅ ¡Recursos aplicados!"
echo "⏳ Esperando a que el NLB se provisione (1-2 minutos)..."

MAX_WAIT=120
INTERVAL=10
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
  URL=$(kubectl -n wordpress get svc wordpress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
  if [ -n "$URL" ]; then
    echo ""
    echo "🎉 ¡NLB listo!"
    echo "🔗 URL: http://$URL"
    echo ""
    exit 0
  fi
  echo "   [$((ELAPSED + INTERVAL))s] Aún no está listo..."
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done

echo ""
echo "⚠️  Tiempo de espera agotado."
echo "🔍 Verifica con:"
echo "   kubectl -n wordpress get svc wordpress"
echo "   kubectl -n wordpress get pods"
EOF

chmod +x ${DIR}/deploy.sh

echo "✅ Estructura generada en: $DIR/"
echo "👉 Ejecuta: cd $DIR && ./deploy.sh"
