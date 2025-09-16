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
