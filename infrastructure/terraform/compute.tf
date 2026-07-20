# SSM Parameter para la AMI de AWS 'Amazon ECS-Optimized' con soporte GPU
data "aws_ssm_parameter" "ecs_gpu_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended/image_id"
}

# SSM Parameter para la AMI de AWS 'Amazon ECS-Optimized' estándar (CPU)
data "aws_ssm_parameter" "ecs_cpu_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# CloudWatch Log Group para logs de tareas ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Launch Template para Instancias EC2 (G5 GPU o CPU según var.use_gpu)
resource "aws_launch_template" "ecs_nodes" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = var.use_gpu ? data.aws_ssm_parameter.ecs_gpu_ami.value : data.aws_ssm_parameter.ecs_cpu_ami.value
  instance_type = var.use_gpu ? "g5.xlarge" : var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_instance_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ecs_nodes.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "ECS_CLUSTER=${aws_ecs_cluster.main.name}" >> /etc/ecs/ecs.config
              ${var.use_gpu ? "echo \"ECS_ENABLE_GPU_SUPPORT=true\" >> /etc/ecs/ecs.config" : ""}
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-node"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group para Nodos EC2
resource "aws_autoscaling_group" "ecs_asg" {
  name_prefix         = "${var.project_name}-asg-"
  vpc_zone_identifier = aws_subnet.private[*].id
  min_size            = var.min_capacity
  max_size            = var.max_capacity
  desired_capacity    = var.desired_capacity

  launch_template {
    id      = aws_launch_template.ecs_nodes.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ECS Capacity Provider
resource "aws_ecs_capacity_provider" "nodes" {
  name = "${var.project_name}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "DISABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [aws_ecs_capacity_provider.nodes.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.nodes.name
  }
}

# ECS Task Definition usando ecs_task_definition.json
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = templatefile("${path.module}/ecs_task_definition.json", {
    CONTAINER_NAME        = var.project_name
    ECR_IMAGE_URI         = "${aws_ecr_repository.app.repository_url}:latest"
    CONTAINER_PORT        = var.container_port
    MODEL_S3_BUCKET       = aws_s3_bucket.weights.bucket
    AWS_REGION            = var.aws_region
    LOG_GROUP_NAME        = aws_cloudwatch_log_group.ecs.name
    FORCE_CPU             = var.use_gpu ? "false" : "true"
    MEMORY_RESERVATION    = var.use_gpu ? 14000 : 6000
    RESOURCE_REQUIREMENTS = var.use_gpu ? jsonencode([{ type = "GPU", value = "1" }]) : "[]"
  })
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.nodes.name
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.project_name
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]
}
