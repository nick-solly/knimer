resource "aws_secretsmanager_secret" "workflow_secrets" {
  name                    = "${local.name_prefix}-workflow-secrets"
  recovery_window_in_days = 0

  tags = {
    Name = "${local.name_prefix}-workflow-secrets"
  }
}

resource "aws_secretsmanager_secret_version" "workflow_secrets_value" {
  secret_id     = aws_secretsmanager_secret.workflow_secrets.id
  secret_string = join(" ", [for k, v in var.workflow_secrets : "-credential=${k};${v}"])
}


locals {

  name_prefix = "${var.name_prefix}-knimer"

}
