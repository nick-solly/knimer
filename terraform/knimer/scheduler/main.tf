resource "aws_iam_role" "ecs_events" {
  name = "${local.name_prefix}-events-role"
  tags = {
    Name = "${local.name_prefix}-events-role"
  }

  assume_role_policy = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
DOC
}

resource "aws_iam_role_policy" "ecs_events_run_task_with_any_role" {
  name = "${local.name_prefix}-events-role-policy"
  role = aws_iam_role.ecs_events.id

  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ecs:RunTask",
            "Resource": "${replace(var.task_definition_arn, "/:\\d+$/", ":*")}"
        }
    ]
}
DOC
}

resource "aws_cloudwatch_event_rule" "scheduler" {
  name        = "${local.name_prefix}-scheduler-${substr(md5(each.value), 0, 6)}"
  for_each    = var.schedule_expressions
  description = "Scheduler KNIME trigger"
  tags = {
    Name = "${local.name_prefix}-scheduler"
  }
  schedule_expression = each.value
}

resource "aws_cloudwatch_event_target" "ecs_workflow" {
  for_each = aws_cloudwatch_event_rule.scheduler
  arn      = var.cluster_arn
  rule     = each.value.name
  role_arn = aws_iam_role.ecs_events.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = var.task_definition_arn
    launch_type         = "FARGATE"
    propagate_tags      = "TASK_DEFINITION"

    network_configuration {
      subnets = var.subnet_ids
    }

    tags = {
      Name = "${local.name_prefix}-task"
    }

  }

}

locals {

  name_prefix = "${var.name_prefix}-knimer"



}
