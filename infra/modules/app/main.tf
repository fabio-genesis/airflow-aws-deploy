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

  wait_for_steady_state = true
  deployment_circuit_breaker {
    enable   = true
    rollback = false
  }
    timeouts {
      create = "5m"
      update = "5m"
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

  wait_for_steady_state = true
  deployment_circuit_breaker {
    enable   = true
    rollback = false
  }
    timeouts {
      create = "5m"
      update = "5m"
    }
}

# CloudWatch Log Group for webserver
resource "aws_cloudwatch_log_group" "airflow_webserver" {
  name_prefix       = "/deploy-airflow-on-ecs-fargate/airflow-webserver/"
  retention_in_days = 1
}

# Security Group for webserver service
resource "aws_security_group" "airflow_webserver_service" {
  name_prefix = "airflow-webserver-service-"
  description = "Allow HTTP inbound traffic from load balancer"
  vpc_id      = var.vpc_id
  ingress {
    description     = "HTTP from load balancer"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Task Definition for webserver
resource "aws_ecs_task_definition" "airflow_webserver" {
  family             = "airflow-webserver"
  cpu                = 1024
  memory             = 2048
  execution_role_arn = aws_iam_role.task_execution.arn
  task_role_arn      = aws_iam_role.task_execution.arn
  network_mode       = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {
      name   = "webserver"
      image  = join(":", [aws_ecr_repository.airflow.repository_url, "latest"])
      cpu    = 1024
      memory = 2048
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      healthcheck = {
        command = [
          "CMD",
          "curl",
          "--fail",
          "http://localhost:8080/health"
        ]
        interval = 35
        timeout  = 30
        retries  = 5
      }
      linuxParameters = {
        initProcessEnabled = true
      }
      essential   = true
      command     = ["webserver"]
  environment = var.airflow_task_common_environment
    environment = var.airflow_task_common_environment
      user        = "50000:0"
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow_webserver.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "airflow-webserver"
        }
      }
    }
  ])
}

# ECS Service for webserver
resource "aws_ecs_service" "airflow_webserver" {
  name = "airflow-webserver"
  task_definition = aws_ecs_task_definition.airflow_webserver.arn
  cluster         = aws_ecs_cluster.airflow.id
  deployment_controller {
    type = "ECS"
  }
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 1
  lifecycle {
    ignore_changes = [desired_count]
  }
  enable_execute_command = true
  launch_type            = "FARGATE"
  network_configuration {
    subnets          = var.public_subnet_ids
    assign_public_ip = true
    security_groups  = [aws_security_group.airflow_webserver_service.id]
  }
  platform_version    = "1.4.0"
  scheduling_strategy = "REPLICA"
  load_balancer {
    target_group_arn = var.webserver_tg_arn
    container_name   = "webserver"
    container_port   = 8080
  }
  force_new_deployment = var.force_new_ecs_service_deployment

  wait_for_steady_state = true
  deployment_circuit_breaker {
    enable   = true
    rollback = false
  }
    timeouts {
      create = "5m"
      update = "5m"
    }
}

# Autoscaling Target
resource "aws_appautoscaling_target" "airflow_webserver" {
  max_capacity       = 1
  min_capacity       = 0
  resource_id        = "service/${aws_ecs_cluster.airflow.name}/${aws_ecs_service.airflow_webserver.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Scheduled scale in (zero at night)
resource "aws_appautoscaling_scheduled_action" "airflow_webserver_scheduled_scale_in" {
  name               = "airflow-webserver-scheduled-scale-in"
  service_namespace  = aws_appautoscaling_target.airflow_webserver.service_namespace
  resource_id        = aws_appautoscaling_target.airflow_webserver.resource_id
  scalable_dimension = aws_appautoscaling_target.airflow_webserver.scalable_dimension
  schedule = "cron(0 13 * * ? *)"
  scalable_target_action {
    min_capacity = 0
    max_capacity = 0
  }
}

# Scheduled scale out (um durante o dia)
resource "aws_appautoscaling_scheduled_action" "airflow_webserver_scheduled_scale_out" {
  name               = "airflow-webserver-scheduled-scale-out"
  service_namespace  = aws_appautoscaling_target.airflow_webserver.service_namespace
  resource_id        = aws_appautoscaling_target.airflow_webserver.resource_id
  scalable_dimension = aws_appautoscaling_target.airflow_webserver.scalable_dimension
  schedule           = "cron(0 23 * * ? *)"
  scalable_target_action {
    min_capacity = 1
    max_capacity = 1
  }
}
