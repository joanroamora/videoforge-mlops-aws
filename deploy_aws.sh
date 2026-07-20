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

# 2. Inicializar y Aplicar Terraform
echo "📦 [1/4] Inicializando y aplicando Terraform..."
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

# 5. Reiniciar servicio ECS para desplegar la nueva imagen
echo "🔄 [4/4] Desplegando en AWS ECS Cluster ($CLUSTER_NAME)..."
aws ecs update-service --cluster "$CLUSTER_NAME" --service "$SERVICE_NAME" --force-new-deployment --region "$REGION" >/dev/null

echo "================================================================="
echo "✅ ¡DESPLIEGUE EN AWS COMPLETADO CON ÉXITO!"
echo "================================================================="
echo "🌐 API Endpoint: $ALB_DNS"
echo "📜 Documentación Swagger: $ALB_DNS/docs"
echo "🪣 Bucket de Pesos: s3://$WEIGHTS_BUCKET/ltx-video/v2.3/"
echo "================================================================="
