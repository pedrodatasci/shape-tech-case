#!/bin/bash

export AIRFLOW__CORE__LOAD_EXAMPLES=False

# Atualiza pacotes e instala dependências
sudo apt update -y
sudo apt install -y python3-venv python3-pip unzip curl jq awscli

# Cria pasta para o Airflow e ativa ambiente virtual
mkdir -p /home/ec2-user/airflow
cd /home/ec2-user/airflow
python3 -m venv .venv
source .venv/bin/activate

# Usa variáveis passadas pelo Terraform
AIRFLOW_VERSION="${AIRFLOW_VERSION}"
AWS_REGION="${AWS_REGION}"
SECRET_NAME="${AIRFLOW_SECRET_NAME}"

# Instala Apache Airflow
pip install --upgrade pip
pip install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"

# Instala boto3
pip install boto3

# Define AIRFLOW_HOME
export AIRFLOW_HOME=/home/ec2-user/airflow

# Inicializa banco de dados
airflow db init

# Recupera segredo do Secrets Manager
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --region "$AWS_REGION" \
  --secret-id "$SECRET_NAME" \
  --query SecretString \
  --output text)

AIRFLOW_USERNAME=$(echo "$SECRET_JSON" | jq -r .username)
AIRFLOW_PASSWORD=$(echo "$SECRET_JSON" | jq -r .password)

# Cria usuário admin
airflow users create \
  --username "$AIRFLOW_USERNAME" \
  --firstname Admin \
  --lastname User \
  --role Admin \
  --email admin@example.com \
  --password "$AIRFLOW_PASSWORD"

# Inicia webserver e scheduler em background, ouvindo em todas as interfaces
airflow webserver --port 8080 --host 0.0.0.0 -D
airflow scheduler -D

# Cria pasta de DAGs se não existir
mkdir -p /home/ec2-user/airflow/dags

# Sincroniza DAGs do S3
aws s3 sync s3://shape-fpso-data-pipeline/dags/ /home/ec2-user/airflow/dags/

# Ajusta permissões
chown -R ec2-user:ec2-user /home/ec2-user/airflow/dags