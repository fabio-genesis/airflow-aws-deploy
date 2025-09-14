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

########################################
# ALB / Target Group
########################################
variable "alb_name" {
  description = "Nome do Application Load Balancer"
  type        = string
  default     = "airflow-alb"
}

variable "alb_target_group_name" {
  description = "Nome do Target Group HTTP:8080 (tipo ip)"
  type        = string
  default     = "airflow-tg"
}

variable "alb_health_check_path" {
  description = "Path do health check do ALB -> TG"
  type        = string
  default     = "/"
}

########################################
# ECR: repositório privado para a imagem do Airflow
########################################

variable "ecr_repo_name" {
  description = "Nome do repositório ECR para a imagem do Airflow"
  type        = string
  default     = "airflow-image"
}

variable "ecr_image_tag_mutability" {
  description = "MUTABLE (padrão) ou IMMUTABLE"
  type        = string
  default     = "MUTABLE"
}

########################################
# ECS Task Definition (Airflow API server)
########################################

variable "ecs_task_cpu" {
  description = "CPU units for Fargate task (1024 = 1 vCPU)"
  type        = string
  default     = "512" # 0.5 vCPU
  validation {
    condition     = contains(["256","512","1024","2048","4096"], var.ecs_task_cpu)
    error_message = "ecs_task_cpu deve ser um de: 256, 512, 1024, 2048, 4096."
  }
}

variable "ecs_task_memory" {
  description = "Memory (MiB) for Fargate task"
  type        = string
  default     = "1024" # 1 GiB
}

