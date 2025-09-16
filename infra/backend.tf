terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "ons-dev-dg-00-stage"
    key    = "airflow/terraform.tfstate"
  }
}
