output "s3_bucket_name" {
  value = aws_s3_bucket.airflow_output.bucket
}



output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}



output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "ecs_sg_id" {
  value = aws_security_group.ecs_sg.id
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}


output "rds_endpoint" {
  value = aws_db_instance.airflow_db.address
}

output "rds_port" {
  value = aws_db_instance.airflow_db.port
}

output "airflow_sqlalchemy_conn" {
  description = "SQLAlchemy conn string do RDS (sensível)"
  value       = "postgresql+psycopg2://${var.db_username}:${var.db_password}@${aws_db_instance.airflow_db.address}:${aws_db_instance.airflow_db.port}/${var.db_name}?sslmode=require"
  sensitive   = true
}

output "airflow_api_base_url" {
  description = "Base URL do Airflow API via ALB"
  value       = "http://${aws_lb.airflow_alb.dns_name}"
}

output "airflow_logging_base_url" {
  description = "Base URL de logging via ALB"
  value       = "http://${aws_lb.airflow_alb.dns_name}"
}

########################################
# Saídas do ALB/TG
########################################
output "alb_dns_name" {
  description = "DNS público do ALB para acessar a UI do Airflow"
  value       = aws_lb.airflow_alb.dns_name
}

output "alb_arn" {
  value = aws_lb.airflow_alb.arn
}

output "alb_target_group_name" {
  value = aws_lb_target_group.airflow_tg.name
}

output "alb_target_group_arn" {
  value = aws_lb_target_group.airflow_tg.arn
}

output "tg_arn" {
  value = aws_lb_target_group.airflow_tg.arn
}

output "tg_protocol_port" {
  value = "${aws_lb_target_group.airflow_tg.protocol}:${aws_lb_target_group.airflow_tg.port}"
}

output "tg_target_type" {
  value = aws_lb_target_group.airflow_tg.target_type
}

########################################
# ECR: repositório privado para a imagem do Airflow
########################################

output "ecr_repository_url" {
  description = "URL do repositório ECR"
  value       = aws_ecr_repository.airflow_image_repo.repository_url
}

output "ecr_repository_arn" {
  value = aws_ecr_repository.airflow_image_repo.arn
}

output "ecr_login_command" {
  description = "Comando para autenticar no ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} --profile ${var.aws_profile} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

output "docker_build_command" {
  value = "docker build --no-cache -t airflow-image:latest ."
}

output "docker_tag_command" {
  value = "docker tag airflow-image:latest ${aws_ecr_repository.airflow_image_repo.repository_url}:latest"
}

output "docker_push_command" {
  value = "docker push ${aws_ecr_repository.airflow_image_repo.repository_url}:latest"
}

output "airflow_alb_dns" {
  description = "DNS do Application Load Balancer"
  value       = aws_lb.airflow_alb.dns_name
}

output "airflow_url" {
  description = "URL HTTP do Airflow via ALB"
  value       = "http://${aws_lb.airflow_alb.dns_name}"
}