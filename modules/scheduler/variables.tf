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
