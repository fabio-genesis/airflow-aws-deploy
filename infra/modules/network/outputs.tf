output "vpc_id" { value = aws_vpc.this.id }
output "private_subnet_ids" { value = [aws_subnet.private_a.id, aws_subnet.private_b.id] }
output "public_subnet_ids" { value = [aws_subnet.public_a.id, aws_subnet.public_b.id] }

output "base_sg_id" { value = aws_security_group.base.id }

output "alb_sg_id" { value = aws_security_group.airflow_webserver_alb.id }
output "webserver_tg_arn" { value = aws_lb_target_group.airflow_webserver.arn }
output "alb_dns_name" { value = aws_lb.airflow_webserver.dns_name }
