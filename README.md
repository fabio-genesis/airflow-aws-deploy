# airflow-on-ecs-fargate
Um exemplo de como implantar o [Apache Airflow](https://github.com/apache/airflow) no Amazon ECS Fargate.

#### Índice
- [Resumo](#resumo)  
  - [Estrutura do projeto](#estrutura-do-projeto)  
- [Primeiros passos](#primeiros-passos)  
  - [⚙️ Ambiente de desenvolvimento local (opcional)](#️-ambiente-de-desenvolvimento-local-opcional)  
  - [🚀 Configurar um cluster ECS (produção)](#-configurar-um-cluster-ecs-produção)  
- [Tarefas independentes](#tarefas-independentes)  
- [Logs](#logs)  
- [Custo](#custo)  
- [Autoescalonamento](#autoescalonamento)  
- [Exemplos](#exemplos)  
  - [Executar um comando arbitrário como tarefa independente](#executar-um-comando-arbitrário-como-tarefa-independente)  
  - [Abrir um shell em um contêiner de serviço usando ECS exec](#abrir-um-shell-em-um-contêiner-de-serviço-usando-ecs-exec)  
  - [Escalonar manualmente um serviço para zero](#escalonar-manualmente-um-serviço-para-zero)  

---

## Resumo

O objetivo deste projeto é demonstrar como implantar o [Apache Airflow](https://github.com/apache/airflow) no AWS Elastic Container Service usando o provedor de capacidade Fargate. O código deste repositório serve como exemplo para ajudar desenvolvedores a criarem sua própria configuração. No entanto, é possível implantá-lo seguindo as etapas descritas em [Configurar um cluster ECS](#-configurar-um-cluster-ecs-produção).

O Airflow e o ECS possuem muitos recursos e opções de configuração. Este projeto cobre vários casos de uso, por exemplo:  
- Autoescalar workers até zero  
- Redirecionar logs do serviço Airflow para o CloudWatch e para o Kinesis Firehose usando [fluentbit](https://fluentbit.io/)  
- Usar [remote_logging](https://airflow.apache.org/docs/apache-airflow/stable/logging-monitoring/logging-tasks.html#logging-for-tasks) para enviar/receber logs de workers para/de S3  
- Usar o provedor AWS [SecretsManagerBackend](https://airflow.apache.org/docs/apache-airflow-providers-amazon/stable/secrets-backends/aws-secrets-manager.html) para armazenar/consumir configurações sensíveis no [SecretsManager](https://aws.amazon.com/secrets-manager/)  
- Executar um comando único como tarefa ECS independente (ex.: `airflow db init`)  
- Abrir um shell em um contêiner em execução via ECS exec  
- Enviar métricas statsd do Airflow para o CloudWatch  

Esses exemplos de configuração são úteis mesmo para quem não executa Airflow no ECS.

---

### Estrutura do projeto

```
├── build .............................. tudo relacionado à construção de imagens de contêiner
│   ├── dev ............................ config de desenvolvimento referenciada no docker-compose.yml
│   └── prod ........................... config de produção usada para construir a imagem enviada ao ECR
├── dags ............................... diretório AIRFLOW_HOME/dags
├── deploy_airflow_on_ecs_fargate ...... pacote python importável de dags/plugins usado para configs extras
│   ├── celery_config.py ............... configuração customizada do celery
│   └── logging_config.py .............. configuração customizada de logs
├── docker-compose.yml ................. config de build para ambiente de desenvolvimento
├── infrastructure ..................... configuração ECS com terraform
│   ├── terraform.tfvars.template ...... template para variáveis sensíveis necessárias ao deploy
│   └── *.tf ........................... exemplo de configuração do cluster ECS
├── plugins ............................ diretório AIRFLOW_HOME/plugins
└── scripts
    ├── put_airflow_worker_xxx.py ...... envia métricas de autoescalonamento customizadas ao CloudWatch
    └── run_task.py .................... exemplo de script python para executar tarefas independentes no cluster ECS
```

---

## Primeiros passos

### ⚙️ Ambiente de desenvolvimento local (opcional)

> Esta seção é **apenas para desenvolvimento/testes locais** usando Docker Compose.  
> Se o seu objetivo é implantar diretamente em **produção no ECS Fargate**, pule para [🚀 Configurar um cluster ECS (produção)](#-configurar-um-cluster-ecs-produção).

1. Inicializar o banco de metadados  
```shell
docker compose run --rm airflow-cli db init
```

2. Criar um usuário admin  
```shell
docker compose run --rm airflow-cli users create --email airflow@example.com --firstname airflow --lastname airflow --password airflow --username airflow --role Admin
```

3. Iniciar todos os serviços  
```shell
docker compose up -d
```

---

### 🚀 Configurar um cluster ECS (produção)

> A partir daqui, começa a configuração do ambiente em **produção**, implantando o Airflow no Amazon ECS Fargate com Terraform e ECR.  

1. Inicializar diretório terraform  
```shell
terraform -chdir=infrastructure init
```

2. (Opcional) Criar arquivo `terraform.tfvars` e definir variáveis `aws_region`, `metadata_db` e `fernet_key`  
```shell
cp infrastructure/terraform.tfvars.template infrastructure/terraform.tfvars
```

3. Criar repositório ECR para armazenar a imagem customizada do Airflow  
```shell
terraform -chdir=infrastructure apply -target=aws_ecr_repository.airflow
```

4. Obter URI do repositório via `awscli` ou [console AWS](https://console.aws.amazon.com/ecr/repositories)  
```shell
aws ecr describe-repositories
```

5. Autenticar Docker/Podman no ECR  
```shell
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ***.dkr.ecr.us-east-1.amazonaws.com
```

6. Construir e enviar a imagem do contêiner  
```shell
export REPO_URI="***.dkr.ecr.us-east-1.amazonaws.com/deploy-airflow-on-ecs-fargate-airflow"
docker buildx build -t "${REPO_URI}" -f build/prod/Containerfile --platform linux/amd64 .
docker push "${REPO_URI}"
```

7. Implantar a infraestrutura restante  
```shell
terraform -chdir=infrastructure apply
```

8. Inicializar o banco de metadados do Airflow como tarefa ECS independente  
```shell
python3 scripts/run_task.py --wait-tasks-stopped --command 'db init'
```

9. Criar um usuário admin do mesmo modo  
```shell
python3 scripts/run_task.py --wait-tasks-stopped --command   'users create --username airflow --firstname airflow --lastname airflow --password airflow --email airflow@example.com --role Admin'
```

10. Obter e abrir a URI do Load Balancer do webserver  
```shell
aws elbv2 describe-load-balancers
```
