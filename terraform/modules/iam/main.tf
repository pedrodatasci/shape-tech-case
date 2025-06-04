resource "aws_iam_role" "glue_role" {
  name = "shape_glue_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "glue.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_policy" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "shape_glue_s3_access" {
  name = "shape-glue-s3-read"
  role = aws_iam_role.glue_role.name  # nome do recurso da sua role

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::shape-fpso-data-pipeline",
          "arn:aws:s3:::shape-fpso-data-pipeline/*"
        ]
      }
    ]
  })
}