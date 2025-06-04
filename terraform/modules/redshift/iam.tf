resource "aws_iam_role" "redshift_access_role" {
  name = "RedshiftS3AccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "redshift.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "redshift_s3_policy" {
  name = "RedshiftS3Policy"
  role = aws_iam_role.redshift_access_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
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