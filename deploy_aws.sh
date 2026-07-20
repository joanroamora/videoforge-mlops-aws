#!/usr/bin/env bash
set -e

export BUILDKIT_PROGRESS=plain

REGION="${AWS_REGION:-us-east-1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/infrastructure/terraform"

echo "================================================================="
echo "🚀 VideoForge - AWS Cloud Deployment (ECS GPU + ECR + S3)"
echo "================================================================="

# 1. Verify required CLI tools
command -v aws >/dev/null 2>&1 || { echo "❌ ERROR: AWS CLI is not installed."; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "❌ ERROR: Terraform is not installed."; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ ERROR: Docker is not installed."; exit 1; }

# 2. Initialize and apply Terraform IaC
echo "📦 [1/4] Initializing and applying Terraform infrastructure..."
cd "$TERRAFORM_DIR"
terraform init
terraform apply -auto-approve

ECR_URL=$(terraform output -raw ecr_repository_url)
ALB_DNS=$(terraform output -raw alb_dns_name)
WEIGHTS_BUCKET=$(terraform output -raw s3_weights_bucket)
CLUSTER_NAME="${PROJECT_NAME:-videoforge}-cluster"
SERVICE_NAME="${PROJECT_NAME:-videoforge}-service"

cd "$SCRIPT_DIR"

# 3. Docker authentication with Amazon ECR
echo "🔐 [2/4] Authenticating Docker with Amazon ECR ($REGION)..."
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_URL"

# 4. Build and Push Docker Container Image
echo "🐳 [3/4] Building GPU Docker image (plain-text log mode)..."
docker build --progress=plain -f docker/Dockerfile -t "$ECR_URL:latest" .

echo "⬆️  Pushing container image to Amazon ECR..."
docker push "$ECR_URL:latest"

# 5. Scale EC2 capacity to 1 and update ECS Service
echo "🔄 [4/4] Scaling compute capacity to 1 and starting ECS service ($CLUSTER_NAME)..."
ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --region "$REGION" --query "AutoScalingGroups[?contains(AutoScalingGroupName, '${PROJECT_NAME:-videoforge}')].AutoScalingGroupName | [0]" --output text)
if [ "$ASG_NAME" != "None" ] && [ -n "$ASG_NAME" ]; then
  aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$ASG_NAME" --min-size 1 --desired-capacity 1 --region "$REGION"
fi

aws ecs update-service --cluster "$CLUSTER_NAME" --service "$SERVICE_NAME" --desired-count 1 --force-new-deployment --region "$REGION" >/dev/null

echo "================================================================="
echo "✅ AWS CLOUD DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo "================================================================="
echo "🌐 API & Web UI Endpoint: $ALB_DNS"
echo "📜 Swagger Documentation: $ALB_DNS/docs"
echo "🪣 Model Weights Bucket: s3://$WEIGHTS_BUCKET/ltx-video/v2.3/"
echo "================================================================="
