from pyspark.context import SparkContext
from pyspark.sql import SparkSession
from datetime import datetime

sc = SparkContext()
spark = SparkSession(sc)

today_str = datetime.today().strftime("%Y-%m-%d")

input_path = f"s3://shape-fpso-data-pipeline/raw/{today_str}/equipment.json"
output_path = "s3://shape-fpso-data-pipeline/bronze/equipment"

df_equipment = spark.read.option("multiline", "true").json(input_path)

df_equipment.write.mode("append").parquet(output_path)
