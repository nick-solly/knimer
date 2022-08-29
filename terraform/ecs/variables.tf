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
}

variable "memory" {
  description = "The amount of memory to allocate to instances of this task"
  type        = number
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

variable "execution_role_arn" {
  description = "The ARN of the ECS Execution Role"
  type        = string
}

variable "task_role_arn" {
  description = "The ARN of the ECS Task Role"
  type        = string
}

variable "workflow_secrets_value_arn" {
  description = "The ARN of the secret containing the KNIME workflow credentials"
  type        = string
}
