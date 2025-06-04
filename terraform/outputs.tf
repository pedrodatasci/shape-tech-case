output "s3_bucket" {
  value = module.s3.bucket_name
}

output "airflow_public_ip" {
  value = module.airflow.instance_public_ip
}