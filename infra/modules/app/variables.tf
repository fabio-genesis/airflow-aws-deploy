variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "airflow_bucket_name" { type = string }
variable "db_address" { type = string }
variable "db_port" { type = number }
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}

variable "alb_sg_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "webserver_tg_arn" { type = string }
variable "aws_region" { type = string }
variable "force_new_ecs_service_deployment" { type = bool }

variable "airflow_task_common_environment" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Common environment variables for Airflow tasks"
  default = []
}
