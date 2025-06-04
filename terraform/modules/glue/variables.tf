variable "bucket_name" {
  description = "S3 bucket used for storing scripts and temp data"
  type        = string
}

variable "glue_role_arn" {
  description = "IAM Role ARN with Glue permissions"
  type        = string
}