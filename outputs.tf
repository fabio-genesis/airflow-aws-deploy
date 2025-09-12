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
  value = data.aws_lb_target_group.existing_tg.arn
}

output "tg_protocol_port" {
  value = "${data.aws_lb_target_group.existing_tg.protocol}:${data.aws_lb_target_group.existing_tg.port}"
}

output "tg_target_type" {
  value = data.aws_lb_target_group.existing_tg.target_type
}

########################################
# Saídas do ECR
########################################

output "ecr_repo_name" {
  value = aws_ecr_repository.airflow.name
}

output "ecr_repo_url" {
  value = aws_ecr_repository.airflow.repository_url
}

output "ecr_repo_arn" {
  value = aws_ecr_repository.airflow.arn
}

output "alb_dns" {
  description = "DNS público do ALB"
  value       = aws_lb.airflow_alb.dns_name
}

output "ecs_cluster_id" {
  description = "ID do ECS Cluster"
  value       = aws_ecs_cluster.this.id
}

output "ecs_service_name" {
  description = "Nome do ECS Service (web)"
  value       = aws_ecs_service.airflow_web.name
}

output "web_taskdef_arn" {
  description = "ARN do Task Definition (web)"
  value       = aws_ecs_task_definition.airflow_web.arn
}

output "logs_group" {
  description = "CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.airflow.name
}

output "scheduler_taskdef_arn"  { value = aws_ecs_task_definition.scheduler.arn }
output "triggerer_taskdef_arn"  { value = aws_ecs_task_definition.triggerer.arn }
output "dagproc_taskdef_arn"    { value = aws_ecs_task_definition.dag_processor.arn }

output "scheduler_service_name" { value = aws_ecs_service.scheduler.name }
output "triggerer_service_name" { value = aws_ecs_service.triggerer.name }
output "dagproc_service_name"   { value = aws_ecs_service.dag_processor.name }

output "default_subnet_ids" {
  description = "Subnets da VPC default"
  value       = data.aws_subnets.default.ids
}