output "cluster_arn" {
  value       = aws_ecs_cluster.cluster.arn
  description = "ARN of the ECS cluster"
}

output "task_definition_arn" {
  value       = aws_ecs_task_definition.task_definition.arn
  description = "ARN of the Task Definition"
}
