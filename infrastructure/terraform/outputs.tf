output "alb_dns_name" {
  description = "Punto de acceso publico HTTP para la API de VideoForge"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecr_repository_url" {
  description = "URI del repositorio Amazon ECR para la imagen Docker"
  value       = aws_ecr_repository.app.repository_url
}

output "s3_weights_bucket" {
  description = "Bucket S3 para almacenar los pesos del modelo LTX-Video v2.3 (MODEL_S3_BUCKET)"
  value       = aws_s3_bucket.weights.bucket
}

output "s3_inputs_bucket" {
  description = "Bucket S3 para almacenar las imagenes de entrada"
  value       = aws_s3_bucket.inputs.bucket
}

output "s3_outputs_bucket" {
  description = "Bucket S3 donde se guardan los videos MP4 generados"
  value       = aws_s3_bucket.outputs.bucket
}

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Nombre del servicio ECS"
  value       = aws_ecs_service.app.name
}
