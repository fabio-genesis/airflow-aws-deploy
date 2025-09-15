variable "metadata_db" {
  type = object({
    db_name  = string
    username = string
    password = string
    port     = string
  })
  sensitive = true
}


variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "force_new_ecs_service_deployment" {
  type    = bool
  default = true
}

variable "fernet_key" {
  type      = string
  sensitive = true
}
