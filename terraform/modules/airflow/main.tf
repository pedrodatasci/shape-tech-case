resource "aws_instance" "airflow" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.airflow_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.airflow_instance_profile.name

  # Passa a variável AIRFLOW_SECRET_NAME dinamicamente pro bootstrap.sh
  user_data = templatefile("${path.module}/bootstrap.sh.tpl", {
    AIRFLOW_SECRET_NAME = aws_secretsmanager_secret.airflow_admin_user.name
    AIRFLOW_VERSION     = "2.7.3"
    PYTHON_VERSION      = "3.10"
    AWS_REGION          = "us-east-1"
    CONSTRAINT_URL      = "https://raw.githubusercontent.com/apache/airflow/constraints-2.7.3/constraints-3.10.txt"
  })


  vpc_security_group_ids = [aws_security_group.airflow_sg.id]

  tags = {
    Name = "Airflow EC2"
  }
}

resource "aws_security_group" "airflow_sg" {
  name        = "airflow-sg"
  description = "Allow HTTP access to Airflow"

  ingress {
    description = "Allow SSH only from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
