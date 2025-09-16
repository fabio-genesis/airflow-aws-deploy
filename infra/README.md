# Infraestrutura modular do Airflow

Este diretório implementa a infraestrutura do Airflow em AWS via Terraform, organizada em módulos:

- **modules/network/**: VPC, subnets, internet gateway, security groups base, ALB (se aplicável)
- **modules/database/**: RDS Postgres para metadata do Airflow, subnet group, SG do DB
- **modules/app/**: ECR, ECS cluster, task definitions, serviços (web, scheduler, worker, metrics, standalone), SQS, Kinesis/Firehose, Glue/Athena, IAM roles, S3 buckets, Secrets

## Como rodar

1. Configure variáveis sensíveis em `terraform.tfvars` ou via SSM/Secrets.
2. Execute:
   ```sh
   terraform fmt -recursive
   terraform validate
   terraform plan -out=planfile
   terraform graph -type=plan | dot -Tpng > graph.png
   ```

## Inputs/Outputs principais

Veja cada módulo para variáveis e outputs. O root wiring conecta os módulos conforme dependências:

- `network` exporta VPC/subnets
- `database` recebe VPC/subnets/SGs e exporta dados do DB
- `app` recebe rede, storage, DB, secrets, etc.

## Convenções

- Tags AWS: `Project = "airflow"`, `Env = "dev|prod"`
- Nenhum módulo referencia recursos de outro diretamente; tudo cruza via vars/outputs.
- Use `moved` blocks ou `terraform state mv` para preservar state.

## Evidências

- Grafo de dependências: `graph.png`
- Plano: `planfile`
- Validação: `terraform validate` deve passar
