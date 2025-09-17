FROM apache/airflow:2.8.1-python3.9

USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends gcc libc6-dev libcurl4-openssl-dev libssl-dev \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY --chown=airflow:airflow app/requirements/base.txt /base.txt
COPY --chown=airflow:airflow app/requirements/prod.txt /requirements.txt

USER airflow
RUN pip install --upgrade pip \
  && pip install --no-cache-dir -r /requirements.txt

COPY --chown=airflow:airflow app/dags "${AIRFLOW_HOME}/dags"
COPY --chown=airflow:airflow app/plugins "${AIRFLOW_HOME}/plugins"
COPY --chown=airflow:airflow app/deploy_pkg "${AIRFLOW_HOME}/deploy_pkg"


ENV PYTHONPATH="${AIRFLOW_HOME}/deploy_pkg:${PYTHONPATH}"