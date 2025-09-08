variable "aws_profile" {
  description = "Perfil do AWS CLI (ex.: dev, prod)."
  type        = string
  default     = "ons-dg-00-dev"
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
}

variable "s3_bucket_name" {
  description = "Nome do bucket S3 para saída"
  type        = string
}


variable "ecs_task_execution_role_name" {
  description = "Nome da IAM Role para ECS Tasks"
  type        = string
  default     = "ecsTaskExecutionRole"
}

variable "s3_upload_prefix" {
  description = "Prefixo/pasta no bucket S3 onde o DAG faz upload, ex: 'our-files/'"
  type        = string
  default     = "airflow-dev-test-install/"
}

variable "my_ip_cidr" {
  description = "Seu IP público em CIDR /32 para acessar o RDS temporariamente (ex.: 201.23.45.67/32). Deixe null para não criar."
  type        = string
  default     = null
}


variable "db_engine_preferred_versions" {
  description = "Lista de versoes preferidas do Postgres (na ordem). Ex.: [\"16\", \"15\"]"
  type        = list(string)
  default     = ["16", "15"]
}

variable "db_identifier" {
  description = "Identificador da instancia RDS"
  type        = string
  default     = "airflow-metadata-db"
}


variable "db_username" {
  description = "Usuario mestre do RDS"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Senha do RDS"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Nome do database para o Airflow"
  type        = string
  default     = "airflow"
}
