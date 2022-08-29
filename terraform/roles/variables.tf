variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "s3_bucket_name" {
  description = "The name of the S3 Bucket containing the KNIME workflow file"
  type        = string
}

variable "workflow_secrets_value_arn" {
  description = "The ARN of the secret containing the KNIME workflow credentials"
  type        = string
}
