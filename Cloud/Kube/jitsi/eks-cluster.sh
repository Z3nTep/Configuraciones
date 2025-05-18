#!/bin/bash

# ====== EXPORTS IGUALES AL TUTORIAL ======
export NOM_CLUSTER=demo-cluster-002
export NOM_WORKER_NODE_GROUP=demo-worker-002
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

export AWS_SUBNET_1A=$(aws ec2 describe-subnets \
  --filter "Name=vpc-id,Values=$(aws ec2 describe-vpcs --filter "Name=is-default,Values=true" --query "Vpcs[].VpcId" --output text)" \
  "Name=availability-zone,Values=us-east-1a" \
  --query "Subnets[].SubnetId" --output text)

export AWS_SUBNET_1B=$(aws ec2 describe-subnets \
  --filter "Name=vpc-id,Values=$(aws ec2 describe-vpcs --filter "Name=is-default,Values=true" --query "Vpcs[].VpcId" --output text)" \
  "Name=availability-zone,Values=us-east-1b" \
  --query "Subnets[].SubnetId" --output text)

# ====== GENERA EL YAML DEL CLUSTER ======
cat > demo-eks-eksctl.yaml <<EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: \${NOM_CLUSTER}
  region: us-east-1
  version: "1.32"

iam:
  serviceRoleARN: arn:aws:iam::\${AWS_ACCOUNT_ID}:role/LabRole

vpc:
  subnets:
    public:
      us-east-1a:
        id: "\${AWS_SUBNET_1A}"
      us-east-1b:
        id: "\${AWS_SUBNET_1B}"
  nat:
    gateway: Disable

managedNodeGroups:
  - name: \${NOM_WORKER_NODE_GROUP}
    instanceType: t3.medium
    desiredCapacity: 2
    minSize: 2
    maxSize: 3
    iam:
      instanceRoleARN: arn:aws:iam::\${AWS_ACCOUNT_ID}:role/LabRole
    privateNetworking: false
    volumeSize: 20

addons:
  - name: aws-ebs-csi-driver
    version: latest
    attachPolicyARNs:
      - arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy
EOF

echo "Fichero demo-eks-eksctl.yaml generado:"
cat demo-eks-eksctl.yaml

# ====== CREA EL CLÚSTER Y EL NODEGROUP ======
echo "Creando el clúster y el nodegroup gestionado..."
cat demo-eks-eksctl.yaml | envsubst | eksctl create cluster -f -

echo "¡Listo! Cuando termine, comprueba los nodos con: kubectl get nodes"
