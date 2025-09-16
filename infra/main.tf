module "network" {
  source     = "./modules/network"
  aws_region = var.aws_region
}

module "database" {
  source             = "./modules/database"
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  allowed_sg_ids     = [module.network.base_sg_id, module.app.web_sg_id, module.app.worker_sg_id]
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  db_port            = 5432
}

module "app" {
  source              = "./modules/app"
  vpc_id              = module.network.vpc_id
  private_subnet_ids  = module.network.private_subnet_ids
  airflow_bucket_name = var.airflow_bucket_name
  db_address          = module.database.db_address
  db_port             = module.database.db_port
  db_name             = module.database.db_name
  db_username         = module.database.db_username
  db_password         = var.db_password
}
