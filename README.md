# Airflow no Amazon ECS com Terraform

Este repositório contém a infraestrutura como código (IaC) para implantar o Apache Airflow em contêineres gerenciados pela Amazon ECS (Elastic Container Service) usando Fargate, com o armazenamento de DAGs em um bucket S3 e todas as configurações definidas usando Terraform.

## Arquitetura

A arquitetura deste projeto inclui:

- **Amazon ECS (Fargate)**: Para executar o Airflow em contêineres sem a necessidade de gerenciar servidores
  - **Webserver**: Interface web do Airflow (porta 8080)
  - **Scheduler**: Agendador de tarefas do Airflow
- **Amazon RDS (PostgreSQL)**: Para o banco de dados do Airflow
- **Amazon S3**: Para armazenar as DAGs do Airflow
- **Amazon VPC**: Com sub-redes públicas e privadas
- **Amazon ECR**: Para armazenar a imagem personalizada do Airflow
- **Application Load Balancer**: Para distribuir tráfego para o webserver

## Melhorias Recentes

Este repositório foi atualizado com as seguintes correções críticas:

### ✅ Problemas Corrigidos
- **Docker Entrypoint**: Corrigido loop infinito que impedia a inicialização do Airflow
- **Dependências**: Corrigido caminho do requirements.txt e adicionadas dependências essenciais
- **Inicialização do Banco**: Adicionada inicialização automática do banco de dados do Airflow
- **Separação de Serviços**: Webserver e Scheduler agora executam em serviços ECS separados
- **Health Checks**: Adicionados health checks para monitoramento adequado
- **Tratamento de Erros**: Melhorado tratamento de erros no script de inicialização
- **Sincronização S3**: Aprimorada sincronização de DAGs do S3 com tratamento de erros

### 🔧 Componentes Principais
- **Webserver**: Responsável pela interface web (http://load-balancer-dns)
- **Scheduler**: Responsável pelo agendamento e execução de tarefas
- **Sincronização S3**: Sincronização automática de DAGs a cada 30 segundos

## Pré-requisitos

- AWS CLI configurada
- Terraform instalado (v1.0.0+)
- Docker instalado
- Permissões na AWS para criar e gerenciar os recursos necessários

## Configuração e Deploy

### Configuração Simples (Root Terraform)

Para uma configuração mais simples e direta, você pode usar os arquivos terraform na raiz do projeto:

#### 1. Configurar Variáveis

```bash
# Copie o arquivo de exemplo
cp terraform.tfvars.example terraform.tfvars

# Edite com seus valores
nano terraform.tfvars
```

#### 2. Deploy da Infraestrutura

```bash
# Inicialize o Terraform
terraform init

# Revise o plano de execução
terraform plan

# Execute o deploy
terraform apply
```

Este método criará automaticamente:
- ✅ **Bucket S3** com pastas `dags/` e `airflow-outputs/`
- ✅ **IAM Roles** com permissões apropriadas para S3
- ✅ **RDS PostgreSQL** para metadados do Airflow
- ✅ **Security Groups** configurados corretamente
- ✅ **VPC e Subnets** usando a VPC padrão

### Configuração Modular (Terraform Modules)

Para uma configuração mais avançada usando módulos terraform, veja a pasta `terraform/`:

### 1. Clonar o repositório

```bash
git clone https://github.com/seu-usuario/airflow-ecs-terraform.git
cd airflow-ecs-terraform
```

### 2. Construir a imagem Docker do Airflow

```bash
cd docker
docker build -t airflow-on-ecs-fargate .
```

### 3. Autenticar no Amazon ECR

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 730335315247.dkr.ecr.us-east-1.amazonaws.com
```

### 4. Criar um repositório no ECR (se ainda não existir)

```bash
aws ecr create-repository --repository-name airflow-on-ecs-fargate --region us-east-1
```

### 5. Taguear e enviar a imagem para o ECR

```bash
docker tag airflow-on-ecs-fargate:latest 730335315247.dkr.ecr.us-east-1.amazonaws.com/airflow-on-ecs-fargate:latest
docker push 730335315247.dkr.ecr.us-east-1.amazonaws.com/airflow-on-ecs-fargate:latest
```

### 6. Criar o IAM Role para execução das tarefas do ECS (se ainda não existir)

```bash
# Criar a política que permite acesso ao S3
cat > airflow-s3-access-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::airflow-dev-test-install",
        "arn:aws:s3:::airflow-dev-test-install/*"
      ]
    }
  ]
}
EOF

aws iam create-policy --policy-name AirflowS3AccessPolicy --policy-document file://airflow-s3-access-policy.json

# Criar a role
aws iam create-role --role-name airflow-task-execution-role --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}'

# Anexar políticas à role
aws iam attach-role-policy --role-name airflow-task-execution-role --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
aws iam attach-role-policy --role-name airflow-task-execution-role --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
aws iam attach-role-policy --role-name airflow-task-execution-role --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query 'Account' --output text):policy/AirflowS3AccessPolicy
```

### 7. Implantar a infraestrutura com Terraform

Crie um arquivo `terraform.tfvars` com as variáveis necessárias:

```hcl
db_name = "airflow"
aws_region = "us-east-1"
db_username = "airflow"
db_password = "airflow12345"
iam_role_ecs = "arn:aws:iam::730335315247:role/airflow-task-execution-role"
aws_ecr_repository = "730335315247.dkr.ecr.us-east-1.amazonaws.com/airflow-on-ecs-fargate:latest"
airflow_bucket_name = "airflow-dev-test-install"
```

Em seguida, execute:

```bash
cd ../terraform
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### 8. Acessar a interface do Airflow

Após a implantação bem-sucedida, a URL da interface do Airflow estará disponível nos outputs do Terraform. Acesse a URL em um navegador para usar o Airflow. O endereço será exibido como `airflow_ui_url` nos outputs.

```bash
terraform output airflow_ui_url
```

### 9. Fazer upload das DAGs para o S3

```bash
# Copiar as DAGs para o bucket S3
aws s3 sync ./dags/ s3://airflow-dev-test-install/dags/
```

## Atualização das DAGs

Este sistema está configurado para sincronizar automaticamente as DAGs do bucket S3 com o diretório local do Airflow a cada 30 segundos. Sempre que você adicionar ou modificar uma DAG:

1. Faça o upload da DAG para o bucket S3:
   ```bash
   aws s3 cp minha_dag.py s3://airflow-dev-test-install/dags/
   ```

2. A DAG será sincronizada automaticamente com o container do Airflow em até 30 segundos.

## Testando a DAG de Exemplo

O repositório inclui uma DAG de exemplo (`dags/our_first_dag.py`) que demonstra:
- ✅ Geração de dados sintéticos
- ✅ Transformação de dados 
- ✅ Upload para S3 com tratamento de erros

### Para testar a DAG:

1. **Upload da DAG para S3:**
   ```bash
   aws s3 cp dags/our_first_dag.py s3://your-bucket-name/dags/
   ```

2. **Acesse a interface do Airflow** e procure pela DAG `daily_etl_pipeline_with_transform`

3. **Execute a DAG manualmente** para testar todas as funcionalidades

4. **Verifique os resultados no S3:**
   ```bash
   aws s3 ls s3://your-bucket-name/airflow-outputs/
   ```

### Configuração para Desenvolvimento Local

Para testar localmente sem AWS, defina a variável de ambiente:
```bash
export SKIP_S3=true
```

Isso fará com que a DAG funcione sem tentar acessar o S3.

## Como funciona a sincronização das DAGs

O sistema de sincronização automática funciona da seguinte maneira:

1. Quando o container do Airflow é iniciado, o script `entrypoint.sh` executa uma primeira sincronização com o comando `aws s3 sync`.

2. Em seguida, um processo em background é iniciado para verificar e sincronizar as DAGs a cada 30 segundos.

3. O comando `aws s3 sync` com a flag `--delete` garante que:
   - Novas DAGs sejam adicionadas
   - DAGs modificadas sejam atualizadas
   - DAGs removidas do S3 também sejam removidas do ambiente local

4. O Airflow verifica periodicamente o diretório de DAGs para identificar alterações.

## Limpeza

Para destruir toda a infraestrutura quando não for mais necessária:

```bash
cd terraform
terraform destroy -var-file="terraform.tfvars"
```

## Observações

- A senha do banco de dados está em texto simples nas variáveis do Terraform.