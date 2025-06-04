#!/bin/bash

# Executa terraform output e extrai o nome do bucket
BUCKET=shape-fpso-data-pipeline

echo "Subindo scripts para o bucket: $BUCKET"

aws s3 cp bronze_equipment.py s3://$BUCKET/glue_jobs/bronze_equipment.py
aws s3 cp bronze_failures_log.py s3://$BUCKET/glue_jobs/bronze_failures_log.py
aws s3 cp bronze_sensors.py s3://$BUCKET/glue_jobs/bronze_sensors.py
aws s3 cp silver_failures.py s3://$BUCKET/glue_jobs/silver_failures.py