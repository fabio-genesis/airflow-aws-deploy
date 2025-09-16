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
