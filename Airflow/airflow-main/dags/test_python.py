# Librerias
from datetime import timedelta

from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from airflow.utils.dates import days_ago
# from airflow.hooks import mysql_hook
from airflow.hooks.mysql_hook import MySqlHook
from airflow.contrib.hooks.fs_hook import FSHook
import pandas as pd
from os import listdir
import numpy as np

#import mysql.connector
#from mysql.connector import Error

# Default arguments
default_args = {
    'owner': 'jose',
    'depends_on_past': False,
    'start_date': days_ago(2),
    'email': ['airflow@example.com'],
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(seconds=10),
}

# Instanciando DAG
dag = DAG(
    'data_product_dag',
    default_args=default_args,
    description='A simple tutorial DAG',
    schedule_interval=timedelta(days=1),
)

# Parametros
FILE_CONNECTION_NAME = "fs_test"
MYSQL_CONNECTION_NAME = "mysql_db"

# Función a ejecutar
def print_context(ds, **kwargs):
    print(ds)
    return 'Parte #1'


def preprocessing(df,countries):
    df['Province/State'] = df['Province/State'].replace(np.NaN, 'NULL')
    df_processed = pd.melt(df,
                           id_vars=["Province/State", "Country/Region", "Lat", "Long"],
                           var_name="fecha",
                           value_name="val"). \
        rename(columns={"Province/State": "provincia",
                        "Country/Region": "pais",
                        "Lat": "lat", "Long": "lon"})

    # Parseando fechas
    df_processed['fecha'] = pd.to_datetime(df_processed['fecha'].str.strip(),  # quitamos blank spaces
                                           infer_datetime_format=True)

    df_processed['year'] = df_processed['fecha'].dt.year
    df_processed['month'] = df_processed['fecha'].dt.month
    df_processed['day'] = df_processed['fecha'].dt.day
    df_processed['weekday'] = df_processed['fecha'].dt.weekday

    df_processed.drop(columns="fecha", inplace=True)

    # Casos acumulados
    #     df_processed.sort_values(["year","month","day"],inplace=True)
    #     df_processed[status + "_accum"] = df_processed.groupby(['pais',"provincia"])[status].cumsum()

    df_processed = pd.merge(df_processed, countries, left_on="pais", right_on="name", how="left")

    df_repeated = df_processed.groupby(["pais", "provincia"], as_index=False). \
        agg({"val": "sum"}). \
        groupby(["pais"], as_index=False). \
        agg({"val": "count"}). \
        sort_values("val", ascending=False)

    df_repeated.rename(columns={"val": "repeated"}, inplace=True)
    df_processed = pd.merge(df_processed, df_repeated, on="pais", how="left")
    df_processed.loc[df_processed["repeated"] > 1, "lat"] = df_processed["latitude"]
    df_processed.loc[df_processed["repeated"] > 1, "lon"] = df_processed["longitude"]

    return df_processed[["year", "month", "day", "weekday", "pais", "provincia", "lat", "lon", "val"]]

def test_pandas(**kwargs):
    #print("kwargs:",kwargs)
    #files = list_dir()
    #iris = pd.read_csv("monitor/iris.csv")

    #print(files)

    FILEPATH = FSHook(FILE_CONNECTION_NAME).get_path()
    confirmados_name = "time_series_covid19_confirmed_global.csv"
    muertes_name = "time_series_covid19_deaths_global.csv"
    recuperados_name = "time_series_covid19_recovered_global.csv"
    countries_name = "paises.csv"

    # full_path = f'{FILEPATH}/{file_name}'

    confirmados_df = pd.read_csv(f'{FILEPATH}/{confirmados_name}')
    muertes_df = pd.read_csv(f'{FILEPATH}/{muertes_name}')
    recuperados_df = pd.read_csv(f'{FILEPATH}/{recuperados_name}')
    countries = pd.read_csv(f'{FILEPATH}/{countries_name}')

    confirmados_processed_df = preprocessing(confirmados_df,countries)
    muertes_processed_df = preprocessing(muertes_df,countries)
    recuperados_processed_df = preprocessing(recuperados_df,countries)


    mysql_connection = MySqlHook(mysql_conn_id =  MYSQL_CONNECTION_NAME).get_sqlalchemy_engine()
    with mysql_connection.begin() as connection:

        # Confirmados preprocesados a SQL Table
        confirmados_processed_df.to_sql("confirmados",
                                        con = connection,
                                        schema = 'test',
                                        if_exists = 'replace',
                                        index = False)

        # Muertos preprocesados a SQL Table
        muertes_processed_df.to_sql("muertos",
                                    con=connection,
                                    schema='test',
                                    if_exists='replace',
                                    index=False)

        # Recuperados preprocesados a SQL Table
        recuperados_processed_df.to_sql("recuperados",
                                        con=connection,
                                        schema='test',
                                        if_exists='replace',
                                        index=False)


    return "¡Tablas creadas!"

# Python Operator
t1 = PythonOperator(
    task_id='t1',
    provide_context=True,
    python_callable=print_context,
    dag=dag,
)

t2 = PythonOperator(
    task_id='t2',
    dag=dag,
    python_callable=test_pandas,
    provide_context=True
)

t1 >> t2