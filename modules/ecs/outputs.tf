output "cluster_name" {
  value = aws_ecs_cluster.airflow.name
}

output "cluster_arn" {
  value = aws_ecs_cluster.airflow.arn
}
