output "cluster_id" {
  description = "ID do cluster ECS"
  value       = aws_ecs_cluster.airflow.id
}

output "airflow_alb_dns" {
  description = "DNS name do load balancer do Airflow"
  value       = aws_lb.airflow.dns_name
}

output "airflow_webserver_service_name" {
  description = "Nome do serviço ECS do Airflow Webserver"
  value       = aws_ecs_service.airflow_webserver.name
}

output "airflow_scheduler_service_name" {
  description = "Nome do serviço ECS do Airflow Scheduler"
  value       = aws_ecs_service.airflow_scheduler.name
}