output "workflow_secrets_value_arn" {
  value       = aws_secretsmanager_secret_version.workflow_secrets_value.arn
  description = "The ARN of the secret containing the KNIME workflow credentials"
}
