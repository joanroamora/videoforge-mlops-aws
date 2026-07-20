#!/usr/bin/env bash
set -e

REGION="${AWS_REGION:-us-east-1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/infrastructure/terraform"

echo "================================================================="
echo "🚀 VideoForge - Despliegue en AWS Cloud (ECS GPU + ECR + S3)"
echo "================================================================="

# 1. Comprobar herramientas necesarias
command -v aws >/dev/null 2>&1 || { echo "❌ ERROR: AWS CLI no está instalado."; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "❌ ERROR: Terraform no está instalado."; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ ERROR: Docker no está instalado."; exit 1; }

# 2. Inicializar y Aplicar Terraform (Con capacidad 0 para no cobrar EC2 mientras compila Docker)
echo "📦 [1/4] Inicializando y aplicando Terraform (Capacidad 0 por ahorro)..."
cd "$TERRAFORM_DIR"
terraform init
terraform apply -auto-approve

ECR_URL=$(terraform output -raw ecr_repository_url)
ALB_DNS=$(terraform output -raw alb_dns_name)
WEIGHTS_BUCKET=$(terraform output -raw s3_weights_bucket)
CLUSTER_NAME="${PROJECT_NAME:-videoforge}-cluster"
SERVICE_NAME="${PROJECT_NAME:-videoforge}-service"

cd "$SCRIPT_DIR"

# 3. Autenticación Docker en ECR
echo "🔐 [2/4] Autenticando Docker con Amazon ECR ($REGION)..."
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_URL"

# 4. Construcción y Push de la Imagen Docker
echo "🐳 [3/4] Construyendo la imagen Docker para GPU..."
docker build -f docker/Dockerfile -t "$ECR_URL:latest" .

echo "⬆️  Subiendo la imagen a Amazon ECR..."
docker push "$ECR_URL:latest"

# 5. Encender capacidad EC2 a 1 e Iniciar servicio ECS
echo "🔄 [4/4] Escalando cómputo a 1 e iniciando servicio ECS ($CLUSTER_NAME)..."
ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --region "$REGION" --query "AutoScalingGroups[?contains(AutoScalingGroupName, '${PROJECT_NAME:-videoforge}')].AutoScalingGroupName | [0]" --output text)
if [ "$ASG_NAME" != "None" ] && [ -n "$ASG_NAME" ]; then
  aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$ASG_NAME" --min-size 1 --desired-capacity 1 --region "$REGION"
fi

aws ecs update-service --cluster "$CLUSTER_NAME" --service "$SERVICE_NAME" --desired-count 1 --force-new-deployment --region "$REGION" >/dev/null

echo "================================================================="
echo "✅ ¡DESPLIEGUE EN AWS COMPLETADO CON ÉXITO!"
echo "================================================================="
echo "🌐 API & Web UI Endpoint: $ALB_DNS"
echo "📜 Documentación Swagger: $ALB_DNS/docs"
echo "🪣 Bucket de Pesos: s3://$WEIGHTS_BUCKET/ltx-video/v2.3/"
echo "================================================================="
