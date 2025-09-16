variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "db_name" {
  type        = string
  description = "Nome do banco de dados do Airflow."
}

variable "db_username" {
  type        = string
  description = "Usuário do banco de dados do Airflow."
}

variable "db_password" {
  type        = string
  description = "Senha do banco de dados do Airflow."
  sensitive   = true
}

variable "airflow_bucket_name" {
  type        = string
  description = "Nome do bucket S3 do Airflow."
}

variable "airflow_bucket_arn" {
  type        = string
  description = "ARN do bucket S3 do Airflow."
}
