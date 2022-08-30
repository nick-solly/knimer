variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "slack_webhook_url_secret_arn" {
  description = "ARN of the secret containing the slack webhook url"
  type        = string
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster"
  type        = string
}
