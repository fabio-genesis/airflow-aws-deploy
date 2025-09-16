resource "aws_db_subnet_group" "this" {
  name_prefix = "airflow-metadata-db-"
  subnet_ids  = var.private_subnet_ids
}

resource "aws_security_group" "this" {
  name_prefix = "airflow-metadata-db-"
  description = "Allow inbound traffic to RDS from ECS"
  vpc_id      = var.vpc_id
  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = var.allowed_sg_ids
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "this" {
  identifier_prefix      = "airflow-metadata-db-"
  allocated_storage      = 20
  max_allocated_storage  = 100
  db_subnet_group_name   = aws_db_subnet_group.this.name
  engine                 = "postgres"
  instance_class         = "db.t4g.micro"
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.this.id]
  apply_immediately      = true
  skip_final_snapshot    = true
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  port                   = var.db_port
}
