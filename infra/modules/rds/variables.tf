variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "allowed_sg_ids" { type = list(string) }
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "db_port" {
  type    = number
  default = 5432
}
