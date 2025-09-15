output "queue_url" {
  value = aws_sqs_queue.celery_broker.url
}

output "queue_arn" {
  value = aws_sqs_queue.celery_broker.arn
}
