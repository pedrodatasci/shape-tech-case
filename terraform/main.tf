provider "aws" {
  region = "us-east-1"
}

module "s3" {
  source = "./modules/s3"
}

module "iam" {
  source = "./modules/iam"
}

module "redshift" {
  source = "./modules/redshift"
}

module "glue" {
  source = "./modules/glue"
  bucket_name   = module.s3.bucket_name
  glue_role_arn = module.iam.glue_role_arn
}

module "airflow" {
  source               = "./modules/airflow"
  ami_id               = "ami-0c101f26f147fa7fd"
  instance_type        = "t3.medium"
  my_ip                = "189.6.246.38"
}