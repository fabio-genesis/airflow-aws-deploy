variable "aws_region" {
  type = string
}

variable "force_new_ecs_service_deployment" {
  type = bool
}

variable "airflow_task_common_environment" {
  type = list(object({ name = string, value = string }))
}

variable "airflow_cloud_watch_metrics_namespace" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "ecs_cluster_arn" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "task_role_arn" {
  type = string
}

variable "task_execution_role_arn" {
  type = string
}
