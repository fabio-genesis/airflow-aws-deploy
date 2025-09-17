# Network Module
module "network" {
  source     = "./modules/network"
  aws_region = var.aws_region
}

# ECR Module
module "ecr" {
  source                      = "./modules/ecr"
  ecr_repository_name         = "airflow"
  environment                 = "dev"
  ecs_task_execution_role_arn = var.iam_role_ecs
}

# RDS Module
module "rds" {
  source             = "./modules/rds"
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  allowed_sg_ids     = [module.network.base_sg_id, module.airflow.webserver_sg_id, module.airflow.db_migrate_sg_id]
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  db_port            = 5432
}

# Airflow ECS Module
module "airflow" {
  source              = "./modules/airflow"
  vpc_id              = module.network.vpc_id
  ecr_repository_url  = module.ecr.ecr_repository_url
  private_subnet_ids  = module.network.private_subnet_ids
  airflow_bucket_name = var.airflow_bucket_name
  db_address          = module.rds.db_address
  db_port             = module.rds.db_port
  db_name             = module.rds.db_name
  db_username         = module.rds.db_username
  db_password         = var.db_password
  alb_sg_id           = module.network.alb_sg_id
  public_subnet_ids   = module.network.public_subnet_ids
  webserver_tg_arn    = module.network.webserver_tg_arn
  iam_role_ecs        = var.iam_role_ecs
  aws_region          = var.aws_region
  force_new_ecs_service_deployment = false
  airflow_task_common_environment = [
    {
      name  = "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN"
      value = "postgresql://${var.db_username}:${var.db_password}@${module.rds.db_address}:${module.rds.db_port}/${module.rds.db_name}"
    },
    {
      name  = "AIRFLOW__CORE__EXECUTOR"
      value = "LocalExecutor"
    },
    {
      name  = "AIRFLOW__API__SECRET_KEY"
      value = "airflow-secret-key-change-in-production"
    },
    {
      name  = "AIRFLOW__CORE__LOAD_EXAMPLES"
      value = "False"
    },
    {
      name  = "AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION"
      value = "True"
    },
    {
      name  = "AIRFLOW__CORE__FERNET_KEY"
      value = "fernet-key-change-in-production-32-chars"
    },
    {
      name  = "AIRFLOW__WEBSERVER__BASE_URL"
      value = "http://${module.network.alb_dns_name}"
    },
    {
      name  = "AIRFLOW__CORE__DAGBAG_IMPORT_TIMEOUT"
      value = "30"
    },
    {
      name  = "AIRFLOW__CORE__DAGS_FOLDER"
      value = "/opt/airflow/dags"
    },
    {
      name  = "AIRFLOW__CORE__PLUGINS_FOLDER"
      value = "/opt/airflow/plugins"
    },
    {
      name  = "AIRFLOW__CORE__BASE_LOG_FOLDER"
      value = "/opt/airflow/logs"
    },
    {
      name  = "AIRFLOW__WEBSERVER__EXPOSE_CONFIG"
      value = "True"
    },
    {
      name  = "AIRFLOW__WEBSERVER__SECRET_KEY"
      value = "airflow-secret-key-change-in-production"
    },
    {
      name  = "AIRFLOW__LOGGING__HOSTNAME_CALLABLE"
      value = "socket.gethostname"
    }
  ]
}
