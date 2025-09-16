# Airflow on ECS Fargate – Deploy Modular

Este projeto demonstra como implantar o [Apache Airflow](https://airflow.apache.org/) no Amazon ECS Fargate usando infraestrutura modular com Terraform, Docker e CI/CD.

---

## Estrutura do Projeto

```
├── infra/           # Infraestrutura modular (Terraform)
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── versions.tf
│   ├── README.md
│   └── modules/
│       ├── network/
│       ├── database/
│       └── app/
├── app/             # Código do Airflow
│   ├── dags/
│   ├── plugins/
│   ├── deploy_pkg/
│   └── requirements/
├── containers/
│   ├── Dockerfile
│   └── airflow.env.template
├── scripts/
│   ├── build_image.sh
│   ├── push_ecr.sh
│   ├── run_task.py
│   └── put_airflow_worker_autoscaling_metric_data.py
├── ci/
│   ├── terraform_plan_apply.yml
│   ├── docker_build_push.yml
│   └── lint_test.yml
├── ops/
│   ├── README.md
│   └── runbooks/
├── .env.example
├── .gitignore
├── Makefile
└── README.md
```

---

## Instalação e Deploy

### 1. Pré-requisitos

- [Terraform](https://www.terraform.io/downloads.html) >= 0.13.1
- [Docker](https://docs.docker.com/get-docker/)
- AWS CLI configurado (`~/.aws/credentials`)
- Python 3.9+ (para scripts utilitários)

### 2. Configurar variáveis

Edite `.env.example` e copie para `.env` com seus valores (sem segredos em produção).

Edite `containers/airflow.env.template` conforme seu ambiente.

### 3. Inicializar e validar infraestrutura

```sh
terraform -chdir=infra init
terraform -chdir=infra validate
terraform -chdir=infra plan
```

### 4. Construir e enviar imagem Docker

```sh
make build-prod
export REPO_URI=<uri-do-seu-ecr>
make push
```

### 5. Aplicar infraestrutura

```sh
terraform -chdir=infra apply
```

### 6. Inicializar banco de metadados e criar usuário admin

```sh
python3 scripts/run_task.py --profile <aws-profile> --wait-tasks-stopped --command 'db init'
python3 scripts/run_task.py --profile <aws-profile> --wait-tasks-stopped --command "users create --username airflow --firstname airflow --lastname airflow --password airflow --email airflow@example.com --role Admin"
```

### 7. Acessar Airflow

Recupere o DNS do Load Balancer via AWS CLI:

```sh
aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, 'airflow-webserver')].DNSName | [0]" --output text
```

---

## CI/CD

- Workflows básicos em [`ci/`](ci/) para validação Terraform, build/push Docker e lint/test Python.
- Use o [Makefile](Makefile) para comandos padronizados.

---

## Operação

Consulte [`ops/README.md`](ops/README.md) para procedimentos operacionais e futuros runbooks.

---

## Observações

- Não inclua segredos em arquivos versionados.
- Após validação, remova qualquer pasta antiga fora do padrão atual.
- Para dúvidas sobre módulos, veja [`infra/README.md`](infra/README.md).

---

## Referências

- [Documentação oficial Airflow](https://airflow.apache.org/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)