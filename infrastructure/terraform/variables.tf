variable "aws_region" {
  type        = string
  description = "Región de AWS para el despliegue"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Entorno de despliegue (prod, dev, staging)"
  default     = "prod"
}

variable "project_name" {
  type        = string
  description = "Prefijo para los nombres de recursos"
  default     = "videoforge"
}

variable "use_gpu" {
  type        = bool
  description = "Definir en true para instancias GPU G5. Definir en false para pruebas con CPU."
  default     = false
}

variable "instance_type" {
  type        = string
  description = "Tipo de instancia EC2 para ECS (c5.xlarge para CPU)"
  default     = "c5.xlarge"
}

variable "desired_capacity" {
  type        = number
  description = "Capacidad deseada de instancias EC2 en el Auto Scaling Group"
  default     = 0
}

variable "min_capacity" {
  type        = number
  description = "Capacidad mínima de instancias EC2"
  default     = 0
}

variable "max_capacity" {
  type        = number
  description = "Capacidad máxima de instancias EC2"
  default     = 1
}

variable "container_port" {
  type        = number
  description = "Puerto de la aplicación en el contenedor Docker"
  default     = 8000
}
