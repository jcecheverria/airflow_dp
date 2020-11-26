from datetime import datetime
from airflow import DAG
from airflow.models import Variable
from airflow.operators.python_operator import PythonOperator
from airflow.utils.dates import days_ago

dag = DAG('task_test', description='Another tutorial DAG',
          default_args={
              'owner': 'obed.espinoza',
              'depends_on_past': False,
              'max_active_runs': 5,
              'start_date': days_ago(5)
          },
          schedule_interval='0 1 * * *',
          catchup=True)


def process_func(**kwargs):
    print(kwargs["execution_date"])


t1 = PythonOperator(
    task_id='t1',
    dag=dag,
    python_callable=process_func,
    provide_context=True,
    op_kwargs={
    }
)

t2 = PythonOperator(
    task_id='t2',
    dag=dag,
    python_callable=process_func,
    provide_context=True,
    op_kwargs={

    }
)

t3 = PythonOperator(
    task_id='t3',
    dag=dag,
    python_callable=process_func,
    provide_context=True,
    op_kwargs={

    }
)

t4 = PythonOperator(
    task_id='t4',
    dag=dag,
    python_callable=process_func,
    provide_context=True,
    op_kwargs={
    }
)

t5 = PythonOperator(
    task_id='t5',
    dag=dag,
    python_callable=process_func,
    provide_context=True,
    op_kwargs={
    }
)

t6 = PythonOperator(
    task_id='t6',
    dag=dag,
    python_callable=process_func,
    provide_context=True,
    op_kwargs={

    }
)


t7 = PythonOperator(
    task_id='t7',
    dag=dag,
    python_callable=process_func,
    provide_context=True,
    op_kwargs={

    }
)

t1 >> [t2, t3] >> t4 >> [t5, t6] >> t7