# IAM module inputs to wire later
variable "s3_bucket_arn" {
  type    = string
  default = null
}

variable "sqs_queue_arn" {
  type    = string
  default = null
}

variable "secret_arns" {
  type    = list(string)
  default = null
}
