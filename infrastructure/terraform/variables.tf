variable "aws_region" {
  type        = string
  description = "Target AWS region for deployment"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Deployment environment (prod, dev, staging)"
  default     = "prod"
}

variable "project_name" {
  type        = string
  description = "Resource naming prefix"
  default     = "videoforge"
}

variable "use_gpu" {
  type        = bool
  description = "Set to true for G5 GPU instances (requires GPU vCPU quota > 0). Set to false for cost-optimized CPU testing."
  default     = false
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for ECS cluster (g5.xlarge for GPU, c5.xlarge for CPU)"
  default     = "c5.xlarge"
}

variable "desired_capacity" {
  type        = number
  description = "Desired EC2 instance capacity in Auto Scaling Group (0 default for $0.00 build cost optimization)"
  default     = 0
}

variable "min_capacity" {
  type        = number
  description = "Minimum EC2 instance capacity"
  default     = 0
}

variable "max_capacity" {
  type        = number
  description = "Maximum EC2 instance capacity (strictly capped at 1 for cost control)"
  default     = 1
}

variable "container_port" {
  type        = number
  description = "Application port inside Docker container"
  default     = 8000
}
