output "cluster_arn" {
  value       = aws_ecs_cluster.cluster.arn
  description = "ARN of the ECS cluster"
}
