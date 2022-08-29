variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "cpu" {
  description = "The amount of CPU to allocate to instances of this task"
  type        = number
  default     = 256
}

variable "memory" {
  description = "The amount of memory to allocate to instances of this task"
  type        = number
  default     = 512
}

variable "knime_workflow_file" {
  description = "The name (without .zip) of the KNIME workflow file in the S3 Bucket"
  type        = string
}

variable "s3_bucket_name" {
  description = "The name of the S3 Bucket containing the KNIME workflow file"
  type        = string
}

variable "workflow_variables" {
  description = "The KNIME workflow variables"
  type        = map(string)
}

variable "workflow_secrets" {
  description = "The KNIME workflow secrets"
  type        = map(string)
  sensitive   = true
}
