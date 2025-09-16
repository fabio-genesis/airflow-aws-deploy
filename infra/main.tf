module "network" {
  source     = "./modules/network"
  aws_region = var.aws_region
}

module "rds" {
  source             = "./modules/rds"
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  allowed_sg_ids     = [module.network.base_sg_id, module.airflow.webserver_sg_id]
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  db_port            = 5432
}

module "airflow" {
  source              = "./modules/airflow"
  vpc_id              = module.network.vpc_id
  aws_ecr_repository  = var.aws_ecr_repository
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
  force_new_ecs_service_deployment = true
  airflow_task_common_environment = []
}
