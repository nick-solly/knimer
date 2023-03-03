resource "aws_ssm_parameter" "workflow_secrets" {
  name  = "${local.name_prefix}-workflow-secrets"
  type  = "SecureString"
  value = join(" ", [for k, v in var.workflow_secrets : "-credential=${k};${v}"])

  tags = {
    Name = "${local.name_prefix}-workflow-secrets"
  }

}

locals {

  name_prefix = "${var.name_prefix}-knimer"

}
