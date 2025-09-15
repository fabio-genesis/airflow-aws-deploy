output "fernet_key_arn" {
  value = aws_secretsmanager_secret.fernet_key.arn
}

output "sql_alchemy_conn_arn" {
  value = aws_secretsmanager_secret.sql_alchemy_conn.arn
}

output "celery_result_backend_arn" {
  value = aws_secretsmanager_secret.celery_result_backend.arn
}
