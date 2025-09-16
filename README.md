# Deploying Apache Airflow on AWS ECS Fargate

## Project Overview
This project provides a modularized Terraform configuration to deploy Apache Airflow on AWS ECS Fargate. It leverages various AWS services such as ECS, ECR, S3, IAM, Secrets Manager, and RDS to create a scalable and secure environment for running Airflow workflows.

## Repository Structure
```
.
├── dags/                          # Directory for Airflow DAGs
│   └── our_first_dag.py           # Example DAG
├── deploy_airflow_on_ecs_fargate/ # Python scripts for deployment
│   ├── __init__.py
│   ├── celery_config.py
│   └── logging_config.py
├── docker/                        # Docker configuration files
│   ├── airflow.cfg
│   ├── Containerfile
│   └── requirements.txt
├── modules/                       # Terraform modules
│   ├── athena/
│   ├── celery/
│   ├── ecr/
│   ├── ecs/
│   ├── iam/
│   ├── kinesis/
│   ├── metadata/
│   ├── metrics/
│   ├── scheduler/
│   ├── secret/
│   ├── standalone_task/
│   ├── storage/
│   ├── vpc/
│   ├── webserver/
│   └── worker/
├── scripts/                       # Utility scripts
│   ├── put_airflow_worker_autoscaling_metric_data.py
│   └── run_task.py
├── docker-compose.yml             # Docker Compose configuration
├── main.tf                        # Root Terraform configuration
├── Makefile                       # Makefile for common tasks
├── provider.tf                    # Terraform provider configuration
├── README.md                      # Project documentation
├── terraform.tfvars               # Terraform variables
└── variables.tf                   # Terraform variable definitions
```

## Prerequisites
- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- Docker installed and running

## Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/fabio-genesis/airflow-aws-deploy.git
cd airflow-aws-deploy
```

### 2. Configure Variables
Update the `terraform.tfvars` file with your specific values:
```hcl
fernet_key = "<your_fernet_key>"
metadata_db = {
  host     = "<db_host>"
  port     = <db_port>
  username = "<db_username>"
  password = "<db_password>"
  database = "<db_name>"
}
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Validate Configuration
```bash
terraform validate
```

### 5. Deploy Infrastructure
```bash
terraform apply
```

### 6. Access Airflow
Once the deployment is complete, access the Airflow webserver using the URL provided in the Terraform output.

### Construindo e Enviando a Imagem Docker do Airflow

Para implantar o Apache Airflow no AWS ECS Fargate, é necessário construir e enviar uma imagem Docker customizada para um repositório no Amazon Elastic Container Registry (ECR). Siga os passos abaixo:

#### 1. Criar o Repositório ECR
O repositório ECR é gerenciado pelo módulo `ecr` do Terraform. Para criá-lo, execute:

```powershell
$env:AWS_PROFILE = "ons-dg-00-dev"
$env:AWS_REGION = "us-east-1"
$env:AWS_DEFAULT_REGION = "us-east-1"
terraform apply -target=module.ecr
```

#### 2. Recuperar a URI do Repositório
Use o AWS CLI para obter a URI do repositório ECR:

```powershell
$ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
$REGION = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-1" }
$REPO_URI = (aws ecr describe-repositories --query "repositories[?repositoryName=='deploy-airflow-on-ecs-fargate-airflow'].repositoryUri" --output text)
$REPO_URI
```

#### 3. Autenticar o Docker no ECR
Autentique o Docker para enviar imagens ao repositório ECR:

```powershell
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
```

#### 4. Construir e Enviar a Imagem Docker
Construa a imagem Docker usando o arquivo `docker/Containerfile` e envie-a para o repositório ECR:

```powershell
if (-not $REPO_URI) {
  $REPO_URI = "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/deploy-airflow-on-ecs-fargate-airflow"
}
docker buildx build -t "${REPO_URI}" -f docker/Containerfile --platform linux/amd64 .
docker push "${REPO_URI}"
```

#### 5. Implantar o Restante da Infraestrutura
Depois que a imagem Docker for enviada, implante o restante da infraestrutura:

```powershell
terraform apply
```

#### 6. Inicializar o Banco de Dados de Metadados do Airflow
Você pode inicializar o banco de dados de metadados do Airflow de duas formas:

- **Opção A**: Automaticamente durante o primeiro start do scheduler, adicionando o comando `airflow db upgrade` ao entrypoint.
- **Opção B**: Manualmente usando o ECS Exec após o deploy inicial:

```powershell
py -3 scripts/run_task.py --profile $env:AWS_PROFILE --wait-tasks-stopped --command 'db init'
```

Após inicializar o banco de dados, crie o usuário admin:

```powershell
py -3 scripts/run_task.py --profile $env:AWS_PROFILE --wait-tasks-stopped --command "users create --username airflow --firstname airflow --lastname airflow --password airflow --email airflow@example.com --role Admin"
```

#### 7. Acessar o Webserver do Airflow
Recupere o DNS do Load Balancer para o webserver do Airflow:

```powershell
aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, 'airflow-webserver')].DNSName | [0]" --output text --profile $env:AWS_PROFILE
```

Abra o DNS no navegador para acessar a interface web do Airflow.

## Módulos
Este projeto é modularizado para flexibilidade e reutilização. Abaixo estão os principais módulos:
- **Athena**: Configura consultas e saídas do Athena.
- **IAM**: Gerencia funções e políticas do IAM.
- **Kinesis**: Configura o Kinesis Firehose para streaming de dados.
- **Secret**: Gerencia segredos no AWS Secrets Manager.
- **Metadata**: Configura o banco de dados de metadados.
- **Webserver, Scheduler, Worker**: Implanta os componentes do Airflow no ECS Fargate.
- **Metrics**: Configura monitoramento e métricas.
- **Standalone Task**: Configura tarefas ECS independentes.

## Solução de Problemas
- **Erros de Validação**: Certifique-se de que todas as variáveis necessárias estão definidas no arquivo `terraform.tfvars`.
- **Problemas com a Fernet Key**: A `fernet_key` deve ser uma string codificada em base64 com 32 caracteres.
- **Formato do Metadata DB**: Certifique-se de que o objeto `metadata_db` corresponde ao formato esperado.

## Licença
Este projeto está licenciado sob a Licença MIT. Consulte o arquivo LICENSE para mais detalhes.
