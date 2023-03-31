variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "slack_signing_secret_name" {
  description = "Name of the parameter containing the slack signing secret"
  type        = string
}

variable "slack_signing_secret_arn" {
  description = "ARN of the parameter containing the slack signing secret"
  type        = string
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "ecs_subnets" {
  description = "Subnets to provision the ECS task on"
  type        = list(string)
}

variable "slack_channel_restriction" {
  description = "Optional channel to restrict slash command running"
  type        = string
  default     = ""
}

variable "knimer_ecs_tasks" {
  description = "A map of the ECS Tasks which can be triggered via the slash command. Key is Task Definition ARN, Value is Cluster ARN."
  type        = map(string)
}
