variable "aws_region" {
  type = string
}

variable "airflow_task_common_environment" {
  type = list(object({ name = string, value = string }))
}

variable "fluentbit_image" {
  type = string
}
