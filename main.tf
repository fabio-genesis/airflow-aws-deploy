


locals {
  fluentbit_image = "public.ecr.aws/aws-observability/aws-for-fluent-bit:stable"

  airflow_task_common_environment = [
    {
      name  = "AIRFLOW__WEBSERVER__INSTANCE_NAME"
      value = "deploy-airflow-on-ecs-fargate"
    },
    {
      name  = "AIRFLOW__LOGGING__LOGGING_LEVEL"
      value = "DEBUG"
    },
    {
      name  = "AIRFLOW__LOGGING__REMOTE_BASE_LOG_FOLDER"
      value = "s3://${module.storage.bucket_name}/remote_base_log_folder/"
    },
    {
      name  = "X_AIRFLOW_SQS_CELERY_BROKER_PREDEFINED_QUEUE_URL"
      value = module.celery.queue_url
    },
    # Use the Amazon SecretsManagerBackend to retrieve secret configuration values at
    # runtime from Secret Manager. Only the *name* of the secret is needed here, so an
    # environment variable is acceptable.
    # Another option would be to specify the secret values directly as environment
    # variables using the Task Definition "secrets" attribute. In that case, one would
    # instead set "valueFrom" to the secret ARN (eg. aws_secretsmanager_secret.sql_alchemy_conn.arn)
    {
      name = "AIRFLOW__CORE__SQL_ALCHEMY_CONN_SECRET"
      # Remove the "config_prefix" using `substr`
      value = substr(module.secret.sql_alchemy_conn_arn, 45, -1)
    },
    {
      name  = "AIRFLOW__CORE__FERNET_KEY_SECRET"
      value = substr(module.secret.fernet_key_arn, 45, -1)
    },
    {
      name  = "AIRFLOW__CELERY__RESULT_BACKEND_SECRET"
      value = substr(module.secret.celery_result_backend_arn, 45, -1)
    },
    {
      # Note: Even if one sets this to "True" in airflow.cfg a hidden environment
      # variable overrides it to False
      name  = "AIRFLOW__CORE__LOAD_EXAMPLES"
      value = "True"
    }
  ]

  airflow_cloud_watch_metrics_namespace = "DeployAirflowOnECSFargate"
}

# -----------------------------------------------------------------------------
# Modules (skeleton). Note: subfolders under ./modules currently reference each
# other and some root variables directly. These blocks wire them into the root,
# but you will still need to refactor modules to use inputs/outputs instead of
# direct cross-references for a successful plan/apply.
# -----------------------------------------------------------------------------

module "storage" {
  source = "./modules/storage"
}

module "vpc" {
  source = "./modules/vpc"
  aws_region = var.aws_region
}

module "ecr" {
  source = "./modules/ecr"
}

module "ecs" {
  source = "./modules/ecs"
}

module "celery" {
  source = "./modules/celery"
}

module "kinesis" {
  source = "./modules/kinesis"
  s3_bucket_arn = module.storage.bucket_arn
}

module "iam" {
  source = "./modules/iam"
  sqs_queue_arn = module.celery.queue_arn
  s3_bucket_arn = module.storage.bucket_arn
  secret_arns   = [
    module.secret.fernet_key_arn,
    module.secret.sql_alchemy_conn_arn,
    module.secret.celery_result_backend_arn
  ]
}

module "metadata" {
  source = "./modules/metadata"
  metadata_db        = var.metadata_db
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "secret" {
  source     = "./modules/secret"
  # Pass-through example; module already defines variable "fernet_key"
  fernet_key = var.fernet_key
  db_address = module.metadata.db_address
  db_port    = module.metadata.db_port
  db_name    = module.metadata.db_name
  db_user    = module.metadata.db_user
  db_pass    = module.metadata.db_pass
}

module "scheduler" {
  source = "./modules/scheduler"
  aws_region                           = var.aws_region
  force_new_ecs_service_deployment     = var.force_new_ecs_service_deployment
  airflow_task_common_environment      = local.airflow_task_common_environment
  airflow_cloud_watch_metrics_namespace = local.airflow_cloud_watch_metrics_namespace
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  ecs_cluster_arn        = module.ecs.cluster_arn
  ecs_cluster_name       = module.ecs.cluster_name
  ecr_repository_url     = module.ecr.repository_url
  task_role_arn          = module.iam.task_role_arn
  task_execution_role_arn= module.iam.task_execution_role_arn
}

module "webserver" {
  source = "./modules/webserver"
  aws_region                       = var.aws_region
  force_new_ecs_service_deployment = var.force_new_ecs_service_deployment
  airflow_task_common_environment  = local.airflow_task_common_environment
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  ecs_cluster_arn        = module.ecs.cluster_arn
  ecs_cluster_name       = module.ecs.cluster_name
  ecr_repository_url     = module.ecr.repository_url
  task_role_arn          = module.iam.task_role_arn
  task_execution_role_arn= module.iam.task_execution_role_arn
}

module "worker" {
  source = "./modules/worker"
  aws_region                       = var.aws_region
  force_new_ecs_service_deployment = var.force_new_ecs_service_deployment
  airflow_task_common_environment  = local.airflow_task_common_environment
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  ecs_cluster_arn        = module.ecs.cluster_arn
  ecs_cluster_name       = module.ecs.cluster_name
  ecr_repository_url     = module.ecr.repository_url
  task_role_arn          = module.iam.task_role_arn
  task_execution_role_arn= module.iam.task_execution_role_arn
}

module "metrics" {
  source = "./modules/metrics"
  aws_region                       = var.aws_region
  force_new_ecs_service_deployment = var.force_new_ecs_service_deployment
  airflow_task_common_environment  = local.airflow_task_common_environment
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  ecs_cluster_arn        = module.ecs.cluster_arn
  ecs_cluster_name       = module.ecs.cluster_name
  ecr_repository_url     = module.ecr.repository_url
  task_role_arn          = module.iam.task_role_arn
  task_execution_role_arn= module.iam.task_execution_role_arn
  worker_service_name    = module.worker.service_name
}

module "standalone_task" {
  source = "./modules/standalone_task"
  aws_region                          = var.aws_region
  fluentbit_image                     = local.fluentbit_image
  airflow_task_common_environment     = local.airflow_task_common_environment
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  ecs_cluster_arn        = module.ecs.cluster_arn
  ecs_cluster_name       = module.ecs.cluster_name
  ecr_repository_url     = module.ecr.repository_url
  task_role_arn          = module.iam.task_role_arn
  task_execution_role_arn= module.iam.task_execution_role_arn
  s3_bucket_arn          = module.storage.bucket_arn
  firehose_role_arn      = module.kinesis.firehose_role_arn
}

module "athena" {
  source = "./modules/athena"
  s3_bucket = module.storage.bucket_name
}

