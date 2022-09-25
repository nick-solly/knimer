output "task_definition_arn" {
  value       = module.ecs.task_definition_arn
  description = "ARN of the Task Definition"
}
