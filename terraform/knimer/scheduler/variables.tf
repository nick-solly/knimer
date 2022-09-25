variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "schedule_expressions" {
  description = "The schedules to run the KNIME workflow on (see: https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html)"
  type        = set(string)
  default     = []
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster"
  type        = string
}

variable "task_definition_arn" {
  description = "ARN of the Task Definition"
  type        = string
}

variable "subnet_ids" {
  description = "List of the subnet ids to run the ECS task on"
  type        = list(string)
}
