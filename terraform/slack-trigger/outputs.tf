output "slack_slash_endpoint" {
  description = "The endpoint to point the Slack Slash Command to"
  value       = "${aws_apigatewayv2_stage.lambda.invoke_url}${local.path}"
}
