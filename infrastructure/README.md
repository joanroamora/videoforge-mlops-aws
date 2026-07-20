# Infrastructure as Code (IaC) Documentation - VideoForge AWS Cloud

This directory contains the modular Terraform manifests for provisioning the complete serverless and containerized AWS infrastructure for VideoForge.

---

## 🏛️ Infrastructure Components

```
infrastructure/terraform/
├── main.tf           # Terraform AWS provider setup (us-east-1), constraints & tags
├── variables.tf      # Configurable parameters (use_gpu, instance_type, desired_capacity)
├── networking.tf     # VPC (10.0.0.0/16), 2 Public Subnets, 2 Private Subnets, NAT Gateway, ALB
├── compute.tf        # ECS Cluster, Task Definition template, Launch Template, Auto Scaling Group
├── storage.tf        # ECR Repository (videoforge-ltx) & S3 Buckets (weights, inputs, outputs)
├── iam.tf            # Task Execution Role, Task Role & S3 Least-Privilege Policies
└── outputs.tf        # Exported outputs (ALB DNS name, ECR URI, S3 bucket names)
```

---

## 🔧 Core Parameters (`variables.tf`)

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `aws_region` | `string` | `"us-east-1"` | Target AWS region for deployment |
| `use_gpu` | `bool` | `false` | `true` for GPU `g5.xlarge`, `false` for CPU `c5.xlarge` |
| `instance_type` | `string` | `"c5.xlarge"` | EC2 instance type (`g5.xlarge` or `c5.xlarge`) |
| `desired_capacity` | `number` | `0` | EC2 instance count ($0.00 cost optimization during Docker build) |
| `max_capacity` | `number` | `1` | Strict upper limit of EC2 instances to prevent uncontrolled cost scaling |

---

## 🔐 IAM Security & Policies

- **ECS Task Execution Role**: Grants permission for ECS agent to pull Docker images from ECR and stream logs to CloudWatch (`/ecs/videoforge`).
- **ECS Task Role**: Grants least-privilege read/write access strictly to `videoforge-inputs-*`, `videoforge-outputs-*`, and `videoforge-model-weights-*` S3 buckets.
- **Security Groups**:
  - `alb_sg`: Opens port 80 to public internet traffic.
  - `ecs_nodes_sg`: Restricts container port 8000 ingress **strictly to requests originated from the ALB Security Group**.

---

## 🛠️ Manual Operations Guide

### 1. Provision Infrastructure Only
```bash
cd infrastructure/terraform
terraform init
terraform apply -auto-approve
```

### 2. Teardown Infrastructure
To permanently destroy all 44 AWS resources (including S3 objects and ECR images via `force_destroy = true`):
```bash
cd infrastructure/terraform
terraform destroy -auto-approve
```
