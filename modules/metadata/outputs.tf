output "db_address" {
  value = aws_db_instance.airflow_metadata_db.address
}

output "db_port" {
  value = aws_db_instance.airflow_metadata_db.port
}

output "db_name" {
  value = aws_db_instance.airflow_metadata_db.db_name
}

output "db_user" {
  value = aws_db_instance.airflow_metadata_db.username
}

output "db_pass" {
  value = aws_db_instance.airflow_metadata_db.password
  sensitive = true
}
