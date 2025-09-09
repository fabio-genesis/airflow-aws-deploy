FROM apache/airflow:3.0.1-python3.12

USER airflow

# deps extras
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# (opcional) reforça auth manager FAB
ENV AIRFLOW__CORE__AUTH_MANAGER=airflow.providers.fab.auth_manager.fab_auth_manager.FabAuthManager
ENV AIRFLOW__CORE__EXECUTOR=LocalExecutor
ENV AIRFLOW__LOGGING__HOSTNAME_CALLABLE=socket.gethostname

# NÃO fixa URL do ALB e nem string do DB aqui.
# injetar via ECS Task Definition (env).

# leve os DAGs pra dentro da imagem (ECS não usa volume local)
COPY dags/ /opt/airflow/dags/
