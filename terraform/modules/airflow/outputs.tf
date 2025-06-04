output "instance_public_ip" {
  value = aws_instance.airflow.public_ip
}

output "airflow_url" {
  value = "http://${aws_instance.airflow.public_ip}:8080"
}

output "airflow_admin_secret_name" {
  value = aws_secretsmanager_secret.airflow_admin_user.name
}