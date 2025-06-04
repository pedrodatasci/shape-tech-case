resource "aws_glue_job" "bronze_failures_log" {
  name     = "shape_bronze_failures_log"
  role_arn = var.glue_role_arn

  command {
    name            = "glueetl"
    script_location = "s3://${var.bucket_name}/glue_jobs/bronze_failures_log.py"
    python_version  = "3"
  }

  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X"
  max_retries       = 1

  default_arguments = {
    "--job-language" = "python"
    "--TempDir"      = "s3://${var.bucket_name}/glue_temp/"
    "--enable-metrics" = "true"
  }
}

resource "aws_glue_job" "bronze_sensors" {
  name     = "shape_bronze_sensors"
  role_arn = var.glue_role_arn

  command {
    name            = "glueetl"
    script_location = "s3://${var.bucket_name}/glue_jobs/bronze_sensors.py"
    python_version  = "3"
  }

  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X"
  max_retries       = 1

  default_arguments = {
    "--job-language" = "python"
    "--TempDir"      = "s3://${var.bucket_name}/glue_temp/"
    "--enable-metrics" = "true"
  }
}

resource "aws_glue_job" "bronze_equipment" {
  name     = "shape_bronze_equipment"
  role_arn = var.glue_role_arn

  command {
    name            = "glueetl"
    script_location = "s3://${var.bucket_name}/glue_jobs/bronze_equipment.py"
    python_version  = "3"
  }

  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X"
  max_retries       = 1

  default_arguments = {
    "--job-language" = "python"
    "--TempDir"      = "s3://${var.bucket_name}/glue_temp/"
    "--enable-metrics" = "true"
  }
}

resource "aws_glue_job" "silver_failures" {
  name     = "shape_silver_failures"
  role_arn = var.glue_role_arn

  command {
    name            = "glueetl"
    script_location = "s3://${var.bucket_name}/glue_jobs/silver_failures.py"
    python_version  = "3"
  }

  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X"
  max_retries       = 1

  default_arguments = {
    "--job-language" = "python"
    "--TempDir"      = "s3://${var.bucket_name}/glue_temp/"
    "--enable-metrics" = "true"
  }
}