output "bucket_name" {
  description = "Nome do bucket S3 criado"
  value       = data.aws_s3_bucket.airflow_bucket.id
}

output "bucket_arn" {
  description = "ARN do bucket S3 criado"
  value       = data.aws_s3_bucket.airflow_bucket.arn
}

output "sns_topic_arn" {
  description = "ARN do tópico SNS para notificações de atualização das DAGs"
  value       = aws_sns_topic.airflow_dags_updates.arn
}