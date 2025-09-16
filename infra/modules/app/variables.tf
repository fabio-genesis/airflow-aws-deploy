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
