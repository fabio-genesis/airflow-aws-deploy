variable "metadata_db" {
  type = object({
    db_name  = string
    username = string
    password = string
    port     = string
  })
  sensitive = true
}
