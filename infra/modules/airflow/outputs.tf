output "airflow_bucket_arn" {
  value = aws_s3_bucket.airflow.arn
}

output "cluster_arn" { value = aws_ecs_cluster.airflow.arn }
output "webserver_service_name" { value = aws_ecs_service.airflow_webserver.name }
output "webserver_sg_id" { value = aws_security_group.airflow_webserver_service.id }