########################################
# S3 para saída da pipeline
########################################
resource "aws_s3_bucket" "airflow_output" {
  bucket = var.s3_bucket_name

  tags = {
    Project = "airflow"
    Purpose = "etl-output"
  }
}

# Acesso público (retirar em prd)
resource "aws_s3_bucket_public_access_block" "airflow_output" {
  bucket                  = aws_s3_bucket.airflow_output.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}



########################################
# IAM role para ECS Task executar e escrever no S3
########################################
data "aws_iam_policy_document" "ecs_task_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = var.ecs_task_execution_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_task_trust.json
}

# Política gerenciada padrão da AWS para execução de tasks
resource "aws_iam_role_policy_attachment" "ecs_exec_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Inline policy para permitir PutObject no prefixo do bucket
data "aws_iam_policy_document" "airflow_s3_put_prefix" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.airflow_output.bucket}/${var.s3_upload_prefix}*"
    ]
  }
}

# Prefixos
variable "logs_prefix" {
  description = "Prefixo onde os logs do Airflow serão gravados no S3"
  type        = string
  default     = "airflow-logs/"
}

data "aws_iam_policy_document" "airflow_s3_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject", "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.airflow_output.bucket}/${var.logs_prefix}*",
      "arn:aws:s3:::${aws_s3_bucket.airflow_output.bucket}/${var.s3_upload_prefix}*"
    ]
  }

  statement {
    effect = "Allow"
    actions = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.airflow_output.bucket}"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [
        "${var.logs_prefix}*",
        "${var.s3_upload_prefix}*"
      ]
    }
  }
}

resource "aws_iam_role_policy" "airflow_s3_upload_policy" {
  name   = "AirflowS3AccessPolicy"
  role   = aws_iam_role.airflow_task_role.id
  policy = data.aws_iam_policy_document.airflow_s3_access.json
}

# Policy para logs remotos do Airflow (S3)
resource "aws_iam_role_policy" "airflow_logs_policy" {
  name = "AirflowLogsPolicy"
  role = aws_iam_role.airflow_task_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "ListBucketLogsPrefix",
        Effect = "Allow",
        Action = ["s3:ListBucket"],
        Resource = "arn:aws:s3:::${aws_s3_bucket.airflow_output.bucket}",
        Condition = {
          StringLike = {
            "s3:prefix" = "airflow-logs/*"
          }
        }
      },
      {
        Sid    = "ReadWriteLogsObjects",
        Effect = "Allow",
        Action = ["s3:GetObject","s3:PutObject"],
        Resource = "arn:aws:s3:::${aws_s3_bucket.airflow_output.bucket}/airflow-logs/*"
      }
    ]
  })
}


########################################
# Descobrir VPC default
########################################
data "aws_vpc" "default" {
  default = true
}

########################################
# SG do ALB – público somente na porta 80
########################################
resource "aws_security_group" "alb_sg" {
  name        = "airflow-alb-sg"
  description = "SG do ALB (HTTP publico)"
  vpc_id      = data.aws_vpc.default.id

  # HTTP 80 aberto para internet (apenas ALB)
  ingress {
    description = "HTTP public"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Saida liberada
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Project = "airflow" }
}

########################################
# SG do ECS – recebe trafego somente do ALB na porta 8080
########################################
resource "aws_security_group" "ecs_sg" {
  name        = "airflow-ecs-sg"
  description = "SG do ECS (somente trafego do ALB)"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "Traffic from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # origem = SG do ALB
  }

    // Habilita served logs (streaming) entre services ECS na porta 8793
  ingress {
    description = "Airflow served logs between ECS tasks"
    from_port   = 8793
    to_port     = 8793
    protocol    = "tcp"
    self        = true              // << substituir a referencia ao proprio SG por self=true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Project = "airflow" }
}

########################################
# SG do RDS – recebe trafego somente do ECS na porta 5432
########################################
resource "aws_security_group" "rds_sg" {
  name        = "airflow-rds-sg"
  description = "SG do RDS (PostgreSQL from ECS only)"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "PostgreSQL from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id] # origem = SG do ECS
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Project = "airflow" }
}

########################################
# Regra TEMPORARIA: liberar SEU IP no RDS (para testes locais)
# So cria se var.my_ip_cidr nao for nula.
########################################
resource "aws_security_group_rule" "rds_from_my_ip" {
  count             = var.my_ip_cidr == null ? 0 : 1
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [var.my_ip_cidr]
  security_group_id = aws_security_group.rds_sg.id
  description       = "Temp access from my IP"
}


########################################
# [NOVO] Subnets da VPC default (para o RDS)
########################################
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# [NOVO] Escolhe 2 subnets para o DB Subnet Group
locals {
  db_subnets = slice(data.aws_subnets.default.ids, 0, 2)
}

########################################
# [NOVO] Descobrir versao valida do Postgres na regiao
########################################
data "aws_rds_engine_version" "pg" {
  engine             = "postgres"
  preferred_versions = var.db_engine_preferred_versions
  # Se a lista estiver vazia, pega a default/mais recente da regiao
}

########################################
# [NOVO] DB Subnet Group (exige 2+ AZs)
########################################
resource "aws_db_subnet_group" "airflow_db_subnets" {
  name       = "${var.db_identifier}-subnets"
  subnet_ids = local.db_subnets

  tags = {
    Project = "airflow"
  }
}

########################################
# [NOVO] RDS PostgreSQL (teste: publico = true)
########################################
resource "aws_db_instance" "airflow_db" {
  identifier               = var.db_identifier
  engine                   = "postgres"
  engine_version           = data.aws_rds_engine_version.pg.version   # <<< versao valida auto
  instance_class           = "db.t3.micro"     # free tier
  allocated_storage        = 20

  username                 = var.db_username
  password                 = var.db_password
  db_name                  = var.db_name

  publicly_accessible      = true              # teste com seu IP/32 no SG
  vpc_security_group_ids   = [aws_security_group.rds_sg.id]
  db_subnet_group_name     = aws_db_subnet_group.airflow_db_subnets.name

  skip_final_snapshot      = true              # cuidado em prod
  deletion_protection      = false
  backup_retention_period  = 0

  tags = {
    Project = "airflow"
  }
}

########################################
# Application Load Balancer (ALB)
########################################
resource "aws_lb" "airflow_alb" {
  name               = var.alb_name
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids

  tags = { Project = "airflow" }
}

########################################
# Target Group do Airflow (tipo ip, HTTP:8080)
########################################
resource "aws_lb_target_group" "airflow_tg" {
  name        = var.alb_target_group_name
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"                         # Fargate/ECS usa 'ip'
  vpc_id      = data.aws_vpc.default.id

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = var.alb_health_check_path
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = { Project = "airflow" }
}

########################################
# Listener :80 (HTTP) -> encaminha para o TG
########################################
resource "aws_lb_listener" "http_80" {
  load_balancer_arn = aws_lb.airflow_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.airflow_tg.arn
  }
}


########################################
# ECR: repositório privado para a imagem do Airflow
########################################
resource "aws_ecr_repository" "airflow" {
  name                 = var.ecr_repo_name
  image_tag_mutability = var.ecr_image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Project = "airflow"
    Purpose = "airflow-image"
  }
}

# Lifecycle policy: manter apenas as N imagens mais recentes
resource "aws_ecr_lifecycle_policy" "airflow" {
  repository = aws_ecr_repository.airflow.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last N images, expire older"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = var.ecr_keep_last_images
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_iam_role" "airflow_task_role" {
  name               = "airflow-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_trust.json
  tags = { Project = "airflow" }
}

# Logs do container
resource "aws_cloudwatch_log_group" "airflow" {
  name              = var.logs_group_name
  retention_in_days = 7
  tags = { Project = "airflow" }
}

# Cluster ECS
resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = { Project = "airflow" }
}

resource "aws_ecs_task_definition" "airflow_web" {
  family                   = "airflow-web"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory

  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.airflow_task_role.arn

  container_definitions = jsonencode([
    {
      name       = var.container_name
      image      = "${aws_ecr_repository.airflow.repository_url}:${var.ecr_image_tag}"
      essential  = true
      command    = ["api-server"]
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      environment = local.common_env

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "web"
        }
      }
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = { Project = "airflow" }
}


resource "aws_ecs_service" "airflow_web" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.airflow_web.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.airflow_tg.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.http_80,
    aws_cloudwatch_log_group.airflow
  ]

  tags = { Project = "airflow" }
}


# <<< ADICIONAR >>>
# Ler ALB e Target Group já criados (sem gerenciar)
data "aws_lb" "existing_alb" {
  name = var.alb_name
}

data "aws_lb_target_group" "existing_tg" {
  name = var.alb_target_group_name
}


########################################
# Função auxiliar para container_definitions
########################################
locals {
  common_env = [
    # Core
    { name = "AIRFLOW__CORE__EXECUTOR",                    value = "LocalExecutor" },
    { name = "AIRFLOW__CORE__AUTH_MANAGER",                value = "airflow.providers.fab.auth_manager.fab_auth_manager.FabAuthManager" },
    { name = "AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION", value = "true" },
    { name = "AIRFLOW__CORE__LOAD_EXAMPLES",               value = "false" },
    { name = "AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK",    value = "true" },

    # API/UI (o scheduler usa isto para falar com o web)
    { name = "AIRFLOW__API__AUTH_BACKEND",                 value = "airflow.api.auth.backend.session" },
    { name = "AIRFLOW__API__BASE_URL",                     value = "http://${aws_lb.airflow_alb.dns_name}" },
    { name = "AIRFLOW__CORE__EXECUTION_API_SERVER_URL",    value = "http://${aws_lb.airflow_alb.dns_name}/execution/" },
    { name = "AIRFLOW__LOGGING__BASE_URL",                 value = "http://${aws_lb.airflow_alb.dns_name}" },
    { name = "AIRFLOW__LOGGING__HOSTNAME_CALLABLE",        value = "airflow.utils.net.get_host_ip_address" },
    
    # Remote logging em S3
    { name = "AIRFLOW__LOGGING__REMOTE_LOGGING",            value = "true" },
    { name = "AIRFLOW__LOGGING__REMOTE_BASE_LOG_FOLDER", value = "s3://${var.s3_bucket_name}/airflow-logs/" },
    { name = "AIRFLOW__LOGGING__REMOTE_LOG_CONN_ID",        value = "aws_default" },

    # Banco (RDS) – com SSL
    { name = "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN",        value = "postgresql+psycopg2://${var.db_username}:${var.db_password}@${aws_db_instance.airflow_db.address}:${aws_db_instance.airflow_db.port}/${var.db_name}?sslmode=require" },

    # Região AWS
    { name = "AWS_DEFAULT_REGION",                         value = var.aws_region },

    # Segredos (iguais em TODOS os containers)
    { name = "AIRFLOW__CORE__FERNET_KEY",                  value = var.airflow_fernet_key },
    { name = "AIRFLOW__WEBSERVER__SECRET_KEY",             value = var.airflow_webserver_secret_key },

    { name = "AIRFLOW__CORE__STORE_SERIALIZED_DAGS",           value = "true" },
    { name = "AIRFLOW__CORE__MIN_SERIALIZED_DAG_UPDATE_INTERVAL", value = "30" },
    { name = "AIRFLOW__CORE__MIN_SERIALIZED_DAG_FETCH_INTERVAL",  value = "10" },
    { name = "AIRFLOW__CORE__STORE_DAG_CODE",                   value = "false" },

    { name = "_PIP_ADDITIONAL_REQUIREMENTS", value = "apache-airflow-providers-amazon apache-airflow-providers-fab==2.0.2 pandas==2.1.1 boto3==1.38.21" },
    { name = "AIRFLOW__LOGGING__WORKER_LOG_SERVER_PORT",  value = "8793" },
    { name = "AIRFLOW__LOGGING__TRIGGER_LOG_SERVER_PORT", value = "0" },

    { name = "AIRFLOW__EXECUTION_API__JWT_SECRET",      value = var.execution_api_jwt_secret },
    { name = "AIRFLOW__EXECUTION_API__JWT_ALGORITHM",   value = "HS512" },

    { name = "AIRFLOW_CONN_AWS_DEFAULT", value = "aws://?region_name=${var.aws_region}" },

    { name = "AIRFLOW__CORE__HOSTNAME_CALLABLE",           value = "airflow.utils.net.get_host_ip_address" },

        // Execution API habilitado e com mesmo segredo em todos os services
    { name = "AIRFLOW__EXECUTION_API__ENABLED",            value = "true" }




  ]
}




########################################
# Task Definitions: scheduler, triggerer, dag-processor
########################################
resource "aws_ecs_task_definition" "scheduler" {
  family                   = "airflow-scheduler"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.airflow_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "scheduler"
      image = "${aws_ecr_repository.airflow.repository_url}:${var.ecr_image_tag}"
      essential = true
      command   = ["scheduler"]
      // Expõe 8793 para served logs
      portMappings = [
        { containerPort = 8793, hostPort = 8793, protocol = "tcp" }
      ]
      environment = local.common_env
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.aws_region
          awslogs-group         = var.logs_group_name
          awslogs-stream-prefix = "scheduler"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "triggerer" {
  family                   = "airflow-triggerer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.airflow_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "triggerer"
      image = "${aws_ecr_repository.airflow.repository_url}:${var.ecr_image_tag}"
      essential = true
      command   = ["triggerer"]
      environment = local.common_env
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.aws_region
          awslogs-group         = var.logs_group_name
          awslogs-stream-prefix = "triggerer"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "dag_processor" {
  family                   = "airflow-dag-processor"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.airflow_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "dag-processor"
      image = "${aws_ecr_repository.airflow.repository_url}:${var.ecr_image_tag}"
      essential = true
      command   = ["dag-processor"]
      environment = local.common_env
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.aws_region
          awslogs-group         = var.logs_group_name
          awslogs-stream-prefix = "dagproc"
        }
      }
    }
  ])
}

########################################
# Services: scheduler, triggerer, dag-processor
########################################
resource "aws_ecs_service" "scheduler" {
  name            = "airflow-scheduler"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.scheduler.arn
  desired_count   = var.scheduler_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

}

resource "aws_ecs_service" "triggerer" {
  name            = "airflow-triggerer"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.triggerer.arn
  desired_count   = var.triggerer_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }


}

resource "aws_ecs_service" "dag_processor" {
  name            = "airflow-dag-processor"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.dag_processor.arn
  desired_count   = var.dagproc_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

}