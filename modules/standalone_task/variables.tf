variable "aws_region" {
  type = string
}

variable "airflow_task_common_environment" {
  type = list(object({ name = string, value = string }))
}

variable "fluentbit_image" {
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

variable "s3_bucket_arn" {
  type = string
}

variable "firehose_role_arn" {
  type = string
}
