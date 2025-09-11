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

########################
# ECR
########################
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

variable "ecr_scan_on_push" {
  description = "Habilita image scanning on push"
  type        = bool
  default     = true
}

variable "ecr_keep_last_images" {
  description = "Quantidade de imagens para manter na política de lifecycle"
  type        = number
  default     = 10
}

variable "ecr_image_tag" {
  description = "Tag da imagem a usar no ECS"
  type        = string
  default     = "latest"
}

variable "ecs_cluster_name" {
  description = "Nome do cluster ECS"
  type        = string
  default     = "airflow-ecs-cluster"
}

variable "ecs_service_name" {
  description = "Nome do service ECS (web)"
  type        = string
  default     = "airflow-web"
}

variable "container_name" {
  description = "Nome do container no task definition"
  type        = string
  default     = "airflow-api"
}

variable "container_port" {
  description = "Porta exposta pelo container web"
  type        = number
  default     = 8080
}

variable "ecs_task_cpu" {
  description = "CPU (Fargate) – ex: 256, 512, 1024"
  type        = number
  default     = 512
}

variable "ecs_task_memory" {
  description = "Memória MiB (Fargate) – ex: 1024, 2048"
  type        = number
  default     = 1024
}

variable "logs_group_name" {
  description = "CloudWatch Log Group para ECS"
  type        = string
  default     = "/ecs/airflow"
}

variable "assign_public_ip" {
  description = "Atribui IP público às tasks (dev)"
  type        = bool
  default     = true
}



# CPU/Mem padrão para tasks Fargate
variable "task_cpu" {
  type    = number
  default = 512
}   # 0.5 vCPU

variable "task_memory" {
  type    = number
  default = 1024
}  # 1 GB

# Desired counts dos serviços de fundo
variable "scheduler_desired_count" {
  type    = number
  default = 1
}

variable "triggerer_desired_count" {
  type    = number
  default = 1
}

variable "dagproc_desired_count" {
  type    = number
  default = 1
}


variable "airflow_fernet_key" {
  description = "Chave Fernet do Airflow (opcional em dev, recomendada em prod)."
  type        = string
  default     = ""
}

variable "airflow_webserver_secret_key" {
  description = "Secret key usada pelo webserver (mesma em todos os containers)"
  type        = string
}

variable "execution_api_jwt_secret" {
  description = "Shared JWT secret used by Airflow Execution API"
  type        = string
  sensitive   = true
}

