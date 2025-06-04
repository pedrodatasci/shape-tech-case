resource "tls_private_key" "airflow" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "airflow_key" {
  key_name   = "airflow-key"
  public_key = tls_private_key.airflow.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.airflow.private_key_pem
  filename = "${path.module}/airflow-key.pem"
  file_permission = "0400"
}
