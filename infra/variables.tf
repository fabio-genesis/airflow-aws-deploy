variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "iam_role_ecs" {
  type        = string
  description = "IAM role para execução de tasks."
}

variable "aws_ecr_repository" {
  type        = string
  description = "Nome do repositório ECR do Airflow."
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

