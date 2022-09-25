output "cluster_arn" {
  value       = module.ecs.cluster_arn
  description = "ARN of the ECS cluster"
}

output "task_definition_arn" {
  value       = module.ecs.task_definition_arn
  description = "ARN of the Task Definition"
}
