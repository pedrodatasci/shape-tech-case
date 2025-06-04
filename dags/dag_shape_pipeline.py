from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.decorators import task
from datetime import datetime
import boto3
import logging
import time

default_args = {
    "owner": "shape",
    "start_date": datetime(2024, 1, 1),
    "retries": 1,
}


def trigger_glue_job(job_name, **kwargs):
    client = boto3.client("glue", region_name="us-east-1")
    response = client.start_job_run(JobName=job_name)
    job_run_id = response["JobRunId"]
    logging.info(f"Glue job '{job_name}' iniciado com RunId: {job_run_id}")

    while True:
        status = client.get_job_run(JobName=job_name, RunId=job_run_id)
        state = status["JobRun"]["JobRunState"]
        logging.info(f"Status atual do job {job_name}: {state}")
        if state in ["SUCCEEDED", "FAILED", "STOPPED"]:
            break
        time.sleep(30)

    if state != "SUCCEEDED":
        raise Exception(f"Glue job {job_name} falhou com status: {state}")


def execute_and_wait(client, statement_kwargs):
    """Executa uma query no Redshift e espera até que ela finalize."""
    response = client.execute_statement(**statement_kwargs)
    statement_id = response["Id"]

    while True:
        desc = client.describe_statement(Id=statement_id)
        status = desc["Status"]
        if status == "FINISHED":
            break
        elif status in ["FAILED", "ABORTED"]:
            raise Exception(f"Query Redshift falhou com status: {status}")
        time.sleep(2)

    if desc.get("HasResultSet"):
        return client.get_statement_result(Id=statement_id)
    return None


@task
def check_and_load_redshift():
    client = boto3.client("redshift-data", region_name="us-east-1")

    # Configs
    workgroup_name = "shape-workgroup"
    database = "shape_db"
    secret_arn = "arn:aws:secretsmanager:us-east-1:954780175153:secret:redshift!shape-namespace-admin-qE8tBc"

    def run_query(sql):
        result = execute_and_wait(client, {
            "WorkgroupName": workgroup_name,
            "Database": database,
            "SecretArn": secret_arn,
            "Sql": sql.strip()
        })
        return result

    # Verifica existência da tabela silver
    silver_check = run_query("""
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'silver' AND table_name = 'equipment_failures'
        LIMIT 1;
    """)
    silver_exists = silver_check and silver_check.get("Records")

    if not silver_exists:
        # Criar e fazer COPY da tabela Silver
        run_query("""
            CREATE TABLE silver.equipment_failures (
                equipment_id   VARCHAR,
                sensor_id      INTEGER,
                timestamp      TIMESTAMP,
                temperature    FLOAT4,
                vibration      FLOAT4,
                group_name     VARCHAR,
                name           VARCHAR,
                PRIMARY KEY (equipment_id, sensor_id, timestamp)
            )
            DISTKEY(equipment_id)
            SORTKEY(equipment_id, timestamp);
        """)

        run_query("""
            COPY silver.equipment_failures
            FROM 's3://shape-fpso-data-pipeline/silver/failures_enriched/'
            IAM_ROLE 'arn:aws:iam::954780175153:role/RedshiftS3AccessRole'
            FORMAT AS PARQUET;
        """)
        return

    # Verifica existência da staging
    staging_check = run_query("""
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'staging' AND table_name = 'equipment_failures'
        LIMIT 1;
    """)
    staging_exists = staging_check and staging_check.get("Records")

    if not staging_exists:
        run_query("""
            CREATE TABLE staging.equipment_failures (
                equipment_id   VARCHAR,
                sensor_id      INTEGER,
                timestamp      TIMESTAMP,
                temperature    FLOAT4,
                vibration      FLOAT4,
                group_name     VARCHAR,
                name           VARCHAR,
                PRIMARY KEY (equipment_id, sensor_id, timestamp)
            );
        """)

    # Truncate + Copy + Merge
    run_query("TRUNCATE TABLE staging.equipment_failures;")

    run_query("""
        COPY staging.equipment_failures
        FROM 's3://shape-fpso-data-pipeline/staging/failures_enriched/'
        IAM_ROLE 'arn:aws:iam::954780175153:role/RedshiftS3AccessRole'
        FORMAT AS PARQUET;
    """)

    run_query("CALL merge_equipment_failures();")


with DAG(
    dag_id="shape_fpso_pipeline",
    description="Pipeline para processar dados de sensores de falha em equipamentos FPSO",
    default_args=default_args,
    schedule_interval=None,
    catchup=False,
    tags=["shape", "glue", "fpso"],
) as dag:

    run_bronze_equipament = PythonOperator(
        task_id="run_bronze_equipment_job",
        python_callable=trigger_glue_job,
        op_kwargs={"job_name": "shape_bronze_equipment"},
    )

    run_bronze_failures_log = PythonOperator(
        task_id="run_bronze_failures_log_job",
        python_callable=trigger_glue_job,
        op_kwargs={"job_name": "shape_bronze_failures_log"},
    )

    run_bronze_sensors = PythonOperator(
        task_id="run_bronze_sensors_job",
        python_callable=trigger_glue_job,
        op_kwargs={"job_name": "shape_bronze_sensors"},
    )

    run_silver_failures = PythonOperator(
        task_id="run_silver_failures_job",
        python_callable=trigger_glue_job,
        op_kwargs={"job_name": "shape_silver_failures"},
    )

    run_bronze_equipament >> run_bronze_failures_log >> run_bronze_sensors >> run_silver_failures >> check_and_load_redshift()