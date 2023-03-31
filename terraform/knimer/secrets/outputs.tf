output "workflow_secrets_value_arn" {
  value       = aws_ssm_parameter.workflow_secrets.arn
  description = "The ARN of the parameter containing the KNIME workflow credentials"
}
