import sys
from pyspark.context import SparkContext
from pyspark.sql import SparkSession
from pyspark.sql.functions import regexp_extract, to_timestamp, year, month, dayofmonth
from datetime import datetime

sc = SparkContext()
spark = SparkSession(sc)

today_str = datetime.today().strftime("%Y-%m-%d")

raw_path = f"s3://shape-fpso-data-pipeline/raw/{today_str}/equipment_failure_sensors.txt"
output_path = "s3://shape-fpso-data-pipeline/bronze/failures"

df_raw = spark.read.text(raw_path)

df = df_raw.select(
    to_timestamp(
        regexp_extract("value", r"\[(.*?)\]", 1), "yyyy-MM-dd[ H:m:s]"
    ).alias("timestamp"),
    regexp_extract("value", r"sensor\[(\d+)\]", 1).cast("int").alias("sensor_id"),
    regexp_extract("value", r"temperature\s+([0-9.]+)", 1).cast("float").alias("temperature"),
    regexp_extract("value", r"vibration\s+([-\d.]+)", 1).cast("float").alias("vibration"),
)

df_clean = df.filter("timestamp IS NOT NULL AND sensor_id IS NOT NULL")

df_clean = df_clean.withColumn("year", year("timestamp")).withColumn("month", month("timestamp")).withColumn("day", dayofmonth("timestamp"))

df_clean.write.mode("append").partitionBy("year", "month", "day").parquet(output_path)
