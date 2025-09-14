FROM apache/airflow:3.0.1-python3.12

USER airflow

RUN pip install --no-cache-dir "apache-airflow[webserver,auth]==3.0.1"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install apache-airflow-providers-fab==2.0.2

ENV AIRFLOW__CORE__AUTH_MANAGER=airflow.providers.fab.auth_manager.fab_auth_manager.FabAuthManager
ENV AIRFLOW__CORE__EXECUTOR=LocalExecutor
ENV AIRFLOW__LOGGING__HOSTNAME_CALLABLE=socket.gethostname
ENV AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://postgres:airflowadmin123@airflow-metadata-db.c4r6wi604g82.us-east-1.rds.amazonaws.com:5432/airflow?sslmode=require
ENV AIRFLOW__API__BASE_URL=http://my-airflow-alb-2112436569.us-east-1.elb.amazonaws.com
ENV AIRFLOW__LOGGING__BASE_URL=http://my-airflow-alb-2112436569.us-east-1.elb.amazonaws.com

COPY dags/ /opt/airflow/dags/

RUN airflow db migrate