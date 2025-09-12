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

resource "aws_iam_role_policy" "airflow_s3_upload_policy" {
  name   = "AirflowS3UploadPolicy"
  role   = aws_iam_role.ecs_task_execution_role.id
  policy = data.aws_iam_policy_document.airflow_s3_put_prefix.json
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

