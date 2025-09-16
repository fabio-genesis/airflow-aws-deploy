from airflow import DAG
from datetime import datetime, timedelta
import os
import pandas as pd
import random
import boto3
import logging, traceback
from airflow.exceptions import AirflowException
import inspect

from airflow.operators.python import PythonOperator, get_current_context

def log_and_reraise(fn):
    """
    Decorator that logs full traceback and re-raises, while only passing through
    kwargs that the wrapped function accepts. This avoids Airflow 3 injecting
    context keys (like 'dag') into callables that don't expect them.
    """
    sig = inspect.signature(fn)

    def _wrap(*args, **kwargs):
        try:
            # If the wrapped function accepts **kwargs, just pass through
            if any(p.kind == inspect.Parameter.VAR_KEYWORD for p in sig.parameters.values()):
                return fn(*args, **kwargs)

            # Otherwise, filter to only the parameters present in the signature
            allowed = {name for name in sig.parameters}
            fkwargs = {k: v for k, v in kwargs.items() if k in allowed}
            return fn(*args, **fkwargs)
        except Exception:
            logging.error("Task error:\n%s", traceback.format_exc())
            raise  # preserva o traceback original

    return _wrap

default_args = {
    'owner': 'your-name',
    'retries': 0,
    'retry_delay': timedelta(minutes=1)
}
output_dir = '/opt/airflow/dags/data'
raw_file = 'raw_events.csv'
transformed_file = 'transformed_events.csv'
raw_path = os.path.join(output_dir, raw_file)
transformed_path = os.path.join(output_dir, transformed_file)
# Task 1: Generate dynamic event data
@log_and_reraise
def generate_fake_events():
    events = [
        "Solar flare near Mars", "New AI model released", "Fusion milestone","Celestial event tonight", "Economic policy update", "Storm in Nairobi",
        "New particle at CERN", "NASA Moon base plan", "Tremors in Tokyo", "Open-source boom"
    ]
    sample_events = random.sample(events, 5)
    data = {
        "timestamp": [datetime.now().strftime("%Y-%m-%d %H:%M:%S") for _ in sample_events],
        "event": sample_events,
        "intensity_score": [round(random.uniform(1, 10), 2) for _ in sample_events],
        "category": [random.choice(["Science", "Tech", "Weather", "Space", "Finance"]) for _ in sample_events]
    }
    df = pd.DataFrame(data)
    os.makedirs(output_dir, exist_ok=True)
    df.to_csv(raw_path, index=False)
    print(f"[RAW] Saved to {raw_path}")

# Task 2: Transform data and save new CSV
@log_and_reraise
def transform_and_save_csv():
    df = pd.read_csv(raw_path)
    # Sort by intensity descending
    df_sorted = df.sort_values(by="intensity_score", ascending=False)
    # Save transformed CSV
    df_sorted.to_csv(transformed_path, index=False)
    print(f"[TRANSFORMED] Sorted and saved to {transformed_path}")

# Task 3: Upload to S3
@log_and_reraise
def upload_to_s3(**kwargs):
    # Allow skipping S3 in local/dev without AWS creds
    if os.getenv("SKIP_S3", "").lower() in {"1", "true", "yes", "y"}:
        print("[S3] SKIPPED by SKIP_S3 env var. File remains local at:", transformed_path)
        return

    run_date = kwargs['ds']
    bucket_name = "airflow-dev-test-install"
    s3_key = f"airflow-outputs/events_transformed_{run_date}.csv"
    s3 = boto3.client('s3')
    s3.upload_file(transformed_path, bucket_name, s3_key)
    print(f"Uploaded to s3://{bucket_name}/{s3_key}")

# DAG setup
with DAG(
    dag_id="daily_etl_pipeline_with_transform",
    default_args=default_args,
    description='Simulate a daily ETL flow with transformation and S3 upload',
    start_date=datetime(2025, 5, 24),
    schedule='@daily',
    catchup=False,
) as dag:
    task_generate = PythonOperator(
        task_id='generate_fake_events',
        python_callable=generate_fake_events
    )
    task_transform = PythonOperator(
        task_id='transform_and_save_csv',
        python_callable=transform_and_save_csv
    )
    task_upload = PythonOperator(
        task_id='upload_to_s3',
        python_callable=upload_to_s3,

    )
    # Task flow
    task_generate >> task_transform >> task_upload