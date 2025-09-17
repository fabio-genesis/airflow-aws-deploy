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


resource "aws_cloudwatch_log_group" "airflow_webserver" {
  name_prefix       = "/deploy-airflow-on-ecs-fargate/airflow-webserver/"
  retention_in_days = 1
}

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

# Security Group for database migration task
resource "aws_security_group" "airflow_db_migrate" {
  name_prefix = "airflow-db-migrate-"
  description = "Allow outbound traffic to RDS for database migration"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Task Definition for database migration
resource "aws_ecs_task_definition" "airflow_db_migrate" {
  family             = "airflow-db-migrate"
  cpu                = 512
  memory             = 1024
  execution_role_arn = var.iam_role_ecs
  task_role_arn      = var.iam_role_ecs
  network_mode       = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {
      name   = "db-migrate"
      image  = var.ecr_repository_url
      cpu    = 512
      memory = 1024
      essential   = true
      command     = ["airflow", "db", "migrate"]
      environment = var.airflow_task_common_environment
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow_webserver.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "airflow-db-migrate"
        }
      }
    }
  ])
}

# Task Definition for webserver
resource "aws_ecs_task_definition" "airflow_webserver" {
  family             = "airflow-webserver"
  cpu                = 1024
  memory             = 2048
  execution_role_arn = var.iam_role_ecs
  task_role_arn      = var.iam_role_ecs
  network_mode       = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {
      name   = "webserver"
      image  = var.ecr_repository_url
      cpu    = 1024
      memory = 2048
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      linuxParameters = {
        initProcessEnabled = true
      }
      essential   = true
      command     = ["airflow", "webserver"]
      environment = var.airflow_task_common_environment
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow_webserver.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
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
    ignore_changes = [desired_count, task_definition]
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
    create = "20m"
    update = "20m"
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
