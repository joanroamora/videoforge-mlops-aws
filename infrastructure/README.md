# Infrastructure Architecture (AWS ECS + GPU Nodes)

This directory contains deployment manifests and architecture specifications for VideoForge running on **AWS Elastic Container Service (ECS)** with GPU-accelerated capacity.

## Architecture Overview

```
                      +-----------------------------+
                      |    Application Load Balancer |
                      +--------------+--------------+
                                     |
                                     v
                      +-----------------------------+
                      |   AWS ECS Service (Fargate /|
                      |   EC2 G5 GPU Instance Pool) |
                      +--------------+--------------+
                                     |
                 +-------------------+-------------------+
                 |                                       |
                 v                                       v
   +---------------------------+           +---------------------------+
   | Amazon S3                 |           | Amazon ECR                |
   | - Model Weights (v2.3)    |           | - Docker Image            |
   | - Input Images            |           |   (NVIDIA CUDA 12.1)      |
   | - Rendered MP4 Videos     |           +---------------------------+
   +---------------------------+
```

## Deployment with Terraform

We provide a complete Infrastructure as Code (IaC) setup using Terraform in [`infrastructure/terraform`](file:///home/joanr/agentic-platforms/videoForge/infrastructure/terraform).

### Provisioned Resources:
1. **Amazon VPC**: Public & Private subnets, Internet Gateway, NAT Gateway, Security Groups.
2. **Amazon ECR**: Container repository `videoforge-ltx` with lifecycle retention policy.
3. **Amazon S3**: Buckets for model weights, input images, and rendered videos.
4. **AWS IAM**: Execution Role, Task Role with S3 permissions, and EC2 Instance Profile.
5. **AWS ECS Cluster & EC2 Auto Scaling**: `g5.xlarge` GPU instances with NVIDIA Container Toolkit runtime and GPU Capacity Provider.
6. **Application Load Balancer (ALB)**: HTTP load balancer routing traffic on port 80 to FastAPI on container port 8000.

### Automated Deployment Commands:
```bash
# Make deployment script executable
chmod +x deploy_aws.sh

# Deploy full stack to AWS
./deploy_aws.sh
```

Or manually:
```bash
cd infrastructure/terraform
terraform init
terraform apply
```

