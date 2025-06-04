from pyspark.context import SparkContext
from pyspark.sql import SparkSession
from datetime import datetime

sc = SparkContext()
spark = SparkSession(sc)

today_str = datetime.today().strftime("%Y-%m-%d")
input_path = f"s3://shape-fpso-data-pipeline/raw/{today_str}/equipment_sensors.csv"
output_path = "s3://shape-fpso-data-pipeline/bronze/sensors"

df = spark.read.option("header", True).csv(input_path)

df = df.withColumn("sensor_id", df["sensor_id"].cast("int"))

df.write.mode("append").parquet(output_path)