from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'example_dag',
    default_args=default_args,
    description='Um exemplo de DAG',
    schedule_interval=timedelta(days=1),
    start_date=datetime(2023, 1, 1),
    catchup=False,
    tags=['example'],
) as dag:
    
    inicio = EmptyOperator(
        task_id='inicio',
    )
    
    tarefa = BashOperator(
        task_id='print_date',
        bash_command='date',
    )
    
    fim = EmptyOperator(
        task_id='fim',
    )
    
    inicio >> tarefa >> fim