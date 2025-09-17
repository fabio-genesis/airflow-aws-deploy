resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/21"
  tags = {
    Name = "deploy-airflow-on-ecs-fargate"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "deploy-airflow-on-ecs-fargate"
  }
}

# Route Table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = {
    Name = "deploy-airflow-on-ecs-fargate-public"
  }
}

# Associate public subnets with route table
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "public_a" {
  availability_zone       = "${var.aws_region}a"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.this.id
  tags = {
    Name = "deploy-airflow-on-ecs-fargate-public-a"
  }
}

resource "aws_subnet" "public_b" {
  availability_zone       = "${var.aws_region}b"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.this.id
  tags = {
    Name = "deploy-airflow-on-ecs-fargate-public-b"
  }
}

resource "aws_subnet" "private_a" {
  availability_zone       = "${var.aws_region}a"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.this.id
  tags = {
    Name = "deploy-airflow-on-ecs-fargate-private-a"
  }
}

resource "aws_subnet" "private_b" {
  availability_zone       = "${var.aws_region}b"
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.this.id
  tags = {
    Name = "deploy-airflow-on-ecs-fargate-private-b"
  }
}

resource "aws_security_group" "base" {
  name        = "airflow-base-sg"
  description = "Base SG for Airflow resources"
  vpc_id      = aws_vpc.this.id
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "airflow-base-sg"
  }
}

# Security Group for ALB
resource "aws_security_group" "airflow_webserver_alb" {
  name_prefix = "airflow-webserver-alb-"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.this.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "airflow_webserver" {
  name               = "airflow-webserver"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.airflow_webserver_alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  ip_address_type    = "ipv4"
}

# Target Group
resource "aws_lb_target_group" "airflow_webserver" {
  name        = "airflow-webserver"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.this.id
  health_check {
    enabled = true
    path    = "/"
    interval            = 30
    timeout             = 10
    unhealthy_threshold = 5
  }
}

# Listener
resource "aws_lb_listener" "airflow_webserver" {
  load_balancer_arn = aws_lb.airflow_webserver.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.airflow_webserver.arn
  }
}
