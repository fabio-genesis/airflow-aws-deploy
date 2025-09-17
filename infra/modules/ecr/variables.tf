variable "ecr_repository_name" {
  type        = string
  description = "Name of the ECR repository for Airflow"
  default     = "airflow"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, staging, prod)"
  default     = "dev"
}

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "ARN of the ECS task execution role"
}
