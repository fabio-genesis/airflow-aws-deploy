# Airflow Local (Docker Compose) - Part I

This project sets up Apache Airflow locally with Docker Compose using LocalExecutor, aligned with the tutorial steps.

## What’s included
- Local Postgres for metadata
- Airflow services: webserver, scheduler, triggerer, dag-processor
- Example ETL DAG at `dags/our_first_dag.py`
- Local volumes: `dags`, `logs`, `plugins`, `config`, `tmp`

## Prerequisites
- Docker Desktop (allocate 4–8 GB RAM in Settings if needed)
- VS Code (optional)

## Quick start (Windows PowerShell)

1. Ensure `.env` has:

```
AIRFLOW_UID=50000
```

2. Initialize the DB and create admin user:

```
docker compose up airflow-init
```

3. Start the stack:

```
docker compose up -d
```

4. Open UI: http://localhost:8080  
   Login: airflow / airflow

## Stop and clean

```
docker compose down -v
```

## Notes
- The DAG writes temp files to `/opt/airflow/tmp` (mapped from `./tmp`).
- S3 upload requires AWS creds and bucket; you can comment out the `upload_to_s3` task for Part I.
- If containers restart or UI doesn’t load, increase Docker Desktop memory to at least 4 GB.
