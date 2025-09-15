output "task_role_arn" {
  value = aws_iam_role.airflow_task.arn
}

output "task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}
