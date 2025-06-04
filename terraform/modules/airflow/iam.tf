resource "aws_iam_role" "airflow_ec2_role" {
  name = "airflow-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "airflow_ec2_secret_policy" {
  name = "airflow-ec2-secret-access"
  role = aws_iam_role.airflow_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowAccessToAirflowSecrets",
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = [
          aws_secretsmanager_secret.airflow_admin_user.arn,
          "arn:aws:secretsmanager:us-east-1:954780175153:secret:redshift!shape-namespace-admin-*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "airflow_instance_profile" {
  name = "airflow-ec2-instance-profile"
  role = aws_iam_role.airflow_ec2_role.name
}

resource "aws_iam_role_policy" "airflow_ec2_s3_access" {
  name = "airflow-ec2-s3-access"
  role = aws_iam_role.airflow_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowReadFromAirflowS3Bucket",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::shape-fpso-data-pipeline",
          "arn:aws:s3:::shape-fpso-data-pipeline/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "airflow_ec2_glue_policy" {
  name = "airflow-ec2-glue-access"
  role = aws_iam_role.airflow_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowStartGlueJobs",
        Effect = "Allow",
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun"
        ],
        Resource = "arn:aws:glue:us-east-1:954780175153:job/shape_*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "airflow_ec2_redshift_data_access" {
  name = "airflow-ec2-redshift-data-access"
  role = aws_iam_role.airflow_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowExecuteRedshiftDataAPI",
        Effect = "Allow",
        Action = [
          "redshift-data:ExecuteStatement",
          "redshift-data:GetStatementResult",
          "redshift-data:DescribeStatement"
        ],
        Resource = "*"
      }
    ]
  })
}
