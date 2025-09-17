#!/bin/bash

# Sincronizar as DAGs do S3 para o diretório local do Airflow
echo "Sincronizando DAGs do S3..."
mkdir -p /opt/airflow/dags
aws s3 sync s3://${AIRFLOW_S3_BUCKET}/${AIRFLOW_S3_DAGS_PATH}/ /opt/airflow/dags/

# Configurar o watcher para sincronizar automaticamente as DAGs do S3
echo "Configurando sincronização automática de DAGs..."
(
  while true; do
    aws s3 sync s3://${AIRFLOW_S3_BUCKET}/${AIRFLOW_S3_DAGS_PATH}/ /opt/airflow/dags/ --delete
    echo "DAGs sincronizadas em $(date)"
    sleep 30
  done
) &

# Iniciar o Airflow com o comando passado
echo "Iniciando o Airflow..."
exec /usr/bin/dumb-init -- /entrypoint "$@"