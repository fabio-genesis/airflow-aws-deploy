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