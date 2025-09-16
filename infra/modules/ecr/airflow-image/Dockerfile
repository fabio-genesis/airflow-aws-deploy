FROM apache/airflow:3.0.6-python3.12

# Copy requirements file to container
COPY requirements.txt /tmp/requirements.txt

USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends gcc libc6-dev libcurl4-openssl-dev libssl-dev \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER airflow
RUN pip install --upgrade pip \
  && pip install --no-cache-dir -r /tmp/requirements.txt