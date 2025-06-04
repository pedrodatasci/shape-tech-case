from pyspark.context import SparkContext
from pyspark.sql import SparkSession
from pyspark.sql.functions import year, month, dayofmonth
from datetime import datetime, timedelta
from pyspark.sql import DataFrame
import boto3
from functools import reduce

def load_last_n_days_from_failures(n: int) -> DataFrame:
    dfs = []
    for i in range(n):
        date = datetime.today() - timedelta(days=i)
        path = f"s3://shape-fpso-data-pipeline/bronze/failures/year={date.year}/month={date.month}/day={date.day}"
        try:
            dfs.append(spark.read.parquet(path))
            print(f"Path found and added to further union: {path}")
        except:
            print(f"Path not found or empty: {path}")
    return reduce(lambda df1, df2: df1.union(df2), dfs) if dfs else None

def check_s3_path_exists(bucket: str, prefix: str) -> bool:
    s3 = boto3.client('s3')

    response = s3.list_objects_v2(Bucket=bucket, Prefix=prefix, MaxKeys=1)

    return 'Contents' in response

sc = SparkContext()
spark = SparkSession(sc)

bronze_failures_log_path = "s3://shape-fpso-data-pipeline/bronze/failures"
bronze_sensors_csv = "s3://shape-fpso-data-pipeline/bronze/sensors"
bronze_equipment_json = "s3://shape-fpso-data-pipeline/bronze/equipment"
output_path = "s3://shape-fpso-data-pipeline/silver/failures_enriched"
output_staging_path = "s3://shape-fpso-data-pipeline/staging/failures_enriched"

silver_exists = check_s3_path_exists("shape-fpso-data-pipeline", "silver/failures_enriched")

if not silver_exists:
    df_failures_log = spark.read.parquet(bronze_failures_log_path).dropDuplicates()
else:
    df_failures_log = load_last_n_days_from_failures(3)

df_sensors = spark.read.parquet(bronze_sensors_csv).dropDuplicates()
df_equipment = spark.read.parquet(bronze_equipment_json).dropDuplicates()

df_joined = (
    df_failures_log
    .join(df_sensors, on="sensor_id", how="left")
    .join(df_equipment, on="equipment_id", how="left")
    .withColumn("year", year("timestamp"))
    .withColumn("month", month("timestamp"))
    .withColumn("day", dayofmonth("timestamp"))
    )

if not silver_exists:
    df_joined.write.mode("overwrite").partitionBy("year", "month", "day").parquet(output_path)
else:
    df_dedup = df_joined.dropDuplicates(["equipment_id", "sensor_id", "timestamp"])

    spark.conf.set("spark.sql.sources.partitionOverwriteMode", "dynamic")

    df_dedup.write.mode("overwrite").partitionBy("year", "month", "day").parquet(output_path)
    
    df_dedup.drop("year", "month", "day").write.mode("overwrite").parquet(output_staging_path)
