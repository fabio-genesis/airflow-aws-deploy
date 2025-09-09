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
