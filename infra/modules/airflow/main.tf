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
      image  = var.aws_ecr_repository
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
