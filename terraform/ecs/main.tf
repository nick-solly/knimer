resource "aws_ecs_cluster" "cluster" {
  name = "${local.name_prefix}-cluster"

  tags = {
    Name = "${local.name_prefix}-cluster"
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = "${local.name_prefix}-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  container_definitions    = local.container_definitions_json

  tags = {
    Name = "${local.name_prefix}-task-definition"
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name = "/ecs/${local.name_prefix}-task-log-group"

  tags = {
    Name = "${local.name_prefix}-task-log-group"
  }
}

locals {

  name_prefix = "${var.name_prefix}-knimer"

  env_workflow_variables = join(" ", [for k, v in var.workflow_variables : "-workflow.variable=${k},${v}"])

  container_definitions_json = jsonencode(
    [
      {
        name      = "knimer"
        image     = "ghcr.io/nick-solly/knimer/knimer:latest"
        essential = true
        environment = [
          { name = "KNIME_WORKFLOW_FILE", value = var.knime_workflow_file },
          { name = "S3_BUCKET_NAME", value = var.s3_bucket_name },
          { name = "WORKFLOW_VARIABLES", value = local.env_workflow_variables },
        ]
        secrets = [
          { name = "WORKFLOW_SECRETS", valueFrom = var.workflow_secrets_value_arn },
        ]
        readonlyRootFilesystem = false
        interactive            = true
        pseudoTerminal         = true
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.ecs.name
            awslogs-stream-prefix = "ecs"
            awslogs-region        = var.aws_region
          }
        }
      }
    ]
  )
}
