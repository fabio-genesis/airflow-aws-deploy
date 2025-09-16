resource "aws_ecr_repository" "airflow" {
  name = "deploy-airflow-on-ecs-fargate-airflow"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "airflow" {
  name = "airflow"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "airflow" {
  cluster_name       = aws_ecs_cluster.airflow.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy {
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_sqs_queue" "celery_broker" {
  name_prefix = "airflow-celery-broker-"
}

resource "aws_s3_bucket" "airflow" {
  bucket_prefix = var.airflow_bucket_name
}

# Security Groups para serviços
resource "aws_security_group" "web" {
  name        = "airflow-web-sg"
  description = "SG for Airflow Webserver"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "airflow-web-sg" }
}

resource "aws_security_group" "worker" {
  name        = "airflow-worker-sg"
  description = "SG for Airflow Worker"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 8793
    to_port     = 8793
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "airflow-worker-sg" }
}

# IAM Role para execução de tasks
resource "aws_iam_role" "task_execution" {
  name = "airflow-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# Task Definitions (exemplo simplificado)
resource "aws_ecs_task_definition" "web" {
  family                   = "airflow-web"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.task_execution.arn
  container_definitions    = jsonencode([
    {
      name      = "web"
      image     = aws_ecr_repository.airflow.repository_url
      essential = true
      portMappings = [{ containerPort = 8080, protocol = "tcp" }]
    }
  ])
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "airflow-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.task_execution.arn
  container_definitions    = jsonencode([
    {
      name      = "worker"
      image     = aws_ecr_repository.airflow.repository_url
      essential = true
      portMappings = [{ containerPort = 8793, protocol = "tcp" }]
    }
  ])
}

# ECS Services (exemplo simplificado)
resource "aws_ecs_service" "web" {
  name            = "airflow-web"
  cluster         = aws_ecs_cluster.airflow.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.web.id]
    assign_public_ip = false
  }
}

resource "aws_ecs_service" "worker" {
  name            = "airflow-worker"
  cluster         = aws_ecs_cluster.airflow.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.worker.id]
    assign_public_ip = false
  }
}
