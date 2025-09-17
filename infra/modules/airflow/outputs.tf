output "airflow_bucket_arn" {
  value = aws_s3_bucket.airflow.arn
}

output "cluster_arn" { value = aws_ecs_cluster.airflow.arn }
output "webserver_service_name" { value = aws_ecs_service.airflow_webserver.name }
output "webserver_sg_id" { value = aws_security_group.airflow_webserver_service.id }
output "db_migrate_task_definition_arn" { value = aws_ecs_task_definition.airflow_db_migrate.arn }
output "db_migrate_sg_id" { value = aws_security_group.airflow_db_migrate.id }