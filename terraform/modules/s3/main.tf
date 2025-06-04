resource "aws_s3_bucket" "data_pipeline" {
  bucket = "shape-fpso-data-pipeline"

  force_destroy = true

  tags = {
    Name        = "Shape Data Pipeline"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.data_pipeline.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.data_pipeline.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.data_pipeline.id

  rule {
    id     = "cleanup-raw-temp-files"
    status = "Enabled"

    filter {
      prefix = "raw/temp/"
    }

    expiration {
      days = 7
    }
  }
}