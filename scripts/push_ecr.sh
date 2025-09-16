#!/bin/bash
set -e
# Exemplo: export REPO_URI=123456789012.dkr.ecr.us-east-1.amazonaws.com/deploy-airflow-on-ecs-fargate-airflow
if [ -z "$REPO_URI" ]; then
  echo "Set REPO_URI env var"
  exit 1
fi
aws ecr get-login-password --region ${AWS_REGION:-us-east-1} | docker login --username AWS --password-stdin "$REPO_URI"
docker tag airflow-prod "$REPO_URI:latest"
docker push "$REPO_URI:latest"
