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
    """Decorator for logging exceptions and re-raising as AirflowException."""
    def wrapper(*args, **kwargs):
        try:
            return fn(*args, **kwargs)
        except Exception as e:
            func_name = fn.__name__
            logging.error(f"[{func_name}] FAILED: {e}")
            logging.error(f"[{func_name}] Traceback:\n{traceback.format_exc()}")
            raise AirflowException(f"{func_name} failed: {e}")
    
    wrapper.__name__ = fn.__name__
    wrapper.__doc__ = fn.__doc__
    return wrapper

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
    """Generate fake event data and save to CSV."""
    os.makedirs(output_dir, exist_ok=True)
    
    events = []
    for i in range(50):
        events.append({
            'event_id': f'event_{i:03d}',
            'timestamp': datetime.now() - timedelta(hours=random.randint(0, 72)),
            'user_id': f'user_{random.randint(1, 20):03d}',
            'action': random.choice(['login', 'logout', 'purchase', 'view', 'click']),
            'intensity_score': random.randint(1, 10)
        })
    
    df = pd.DataFrame(events)
    df.to_csv(raw_path, index=False)
    print(f"[GENERATED] {len(events)} events saved to {raw_path}")

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