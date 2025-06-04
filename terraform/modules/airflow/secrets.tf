resource "random_password" "airflow_admin_password" {
  length  = 16
  special = true
}

resource "random_id" "airflow_secret_suffix" {
  byte_length = 4
}

resource "aws_secretsmanager_secret" "airflow_admin_user" {
  name = "airflow-admin-user-${random_id.airflow_secret_suffix.hex}"
}

resource "aws_secretsmanager_secret_version" "airflow_admin_user_version" {
  secret_id     = aws_secretsmanager_secret.airflow_admin_user.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.airflow_admin_password.result
  })
}