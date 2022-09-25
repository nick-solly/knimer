resource "aws_iam_role" "execution_role" {
  name = "${local.name_prefix}-ecs-execution-role"

  tags = {
    Name = "${local.name_prefix}-ecs-execution-role"
  }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "secret_access" {
  name = "${local.name_prefix}-secret-policy"

  tags = {
    Name = "${local.name_prefix}-secret-policy"
  }

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AccessSecrets",
            "Effect": "Allow",
            "Action": [
              "secretsmanager:GetSecretValue"
            ],
            "Resource": ["${var.workflow_secrets_value_arn}"]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "execution_role_secret_access" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.secret_access.arn
}

resource "aws_iam_role" "task_role" {
  name = "${local.name_prefix}-ecs-task-role"

  tags = {
    Name = "${local.name_prefix}-ecs-task-role"
  }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "additional" {
  name = "${local.name_prefix}-ecs-task-policy"

  tags = {
    Name = "${local.name_prefix}-ecs-task-policy"
  }

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
      ]
    },
    {
       "Effect": "Allow",
       "Action": [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
       ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_role_additional_access" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.additional.arn
}

locals {

  name_prefix = "${var.name_prefix}-knimer"

}
