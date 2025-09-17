output "cluster_id" {
  description = "ID do cluster ECS"
  value       = aws_ecs_cluster.airflow.id
}

output "airflow_alb_dns" {
  description = "DNS name do load balancer do Airflow"
  value       = aws_lb.airflow.dns_name
}

output "airflow_service_name" {
  description = "Nome do serviço ECS do Airflow"
  value       = aws_ecs_service.airflow.name
}