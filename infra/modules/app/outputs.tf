output "airflow_bucket_arn" {
  value = aws_s3_bucket.airflow.arn
}

output "web_sg_id" { value = aws_security_group.web.id }
output "worker_sg_id" { value = aws_security_group.worker.id }
output "cluster_arn" { value = aws_ecs_cluster.airflow.arn }
output "service_names" { value = [aws_ecs_service.web.name, aws_ecs_service.worker.name] }
output "ecr_repo_url" { value = aws_ecr_repository.airflow.repository_url }
