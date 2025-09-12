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
