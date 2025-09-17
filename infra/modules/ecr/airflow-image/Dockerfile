FROM apache/airflow:2.8.1-python3.9

USER 0
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
 && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt

USER airflow

WORKDIR /opt/airflow

RUN mkdir -p /opt/airflow/dags /opt/airflow/logs /opt/airflow/plugins

ENV AIRFLOW_HOME=/opt/airflow \
    AIRFLOW__CORE__EXECUTOR=LocalExecutor \
    AIRFLOW__CORE__LOAD_EXAMPLES=False \
    AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION=True \
    AIRFLOW__LOGGING__HOSTNAME_CALLABLE=socket.gethostname

EXPOSE 8080

CMD ["airflow", "webserver"]
