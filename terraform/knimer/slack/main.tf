resource "aws_iam_role" "iam_for_lambda" {
  name = "${local.name_prefix}-lambda-role"

  tags = {
    Name = "${local.name_prefix}-lambda-role"
  }
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "secret_access" {
  name = "${local.name_prefix}-lambda-secret-access-policy"

  tags = {
    Name = "${local.name_prefix}-lambda-secret-access-policy"
  }

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AccessParameters",
            "Effect": "Allow",
            "Action": [
              "ssm:GetParameters"
            ],
            "Resource": ["${var.slack_webhook_url_secret_arn}"]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "execution_role_secret_access" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.secret_access.arn
}

data "archive_file" "zipped_python" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "slacker" {
  filename         = data.archive_file.zipped_python.output_path
  function_name    = "${local.name_prefix}-slack-lambda"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "lambda.lambda_handler"
  source_code_hash = data.archive_file.zipped_python.output_base64sha256
  runtime          = "python3.9"
  architectures    = ["x86_64"]
  tags = {
    Name = "${local.name_prefix}-slack-lambda"
  }

  environment {
    variables = {
      SLACK_WEBHOOK_URL_SECRET_NAME = var.slack_webhook_url_secret_name
      REGION_NAME                   = var.aws_region
    }
  }
}

resource "aws_cloudwatch_event_rule" "ecs_change" {
  name        = "${local.name_prefix}-capture-ecs-change"
  description = "Capture each ECS container state change"
  tags = {
    Name = "${local.name_prefix}-capture-ecs-change"
  }

  event_pattern = <<EOF
{
  "source": ["aws.ecs"],
  "detail-type": ["ECS Task State Change"],
  "detail": {
    "clusterArn": ["${var.cluster_arn}"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  arn  = aws_lambda_function.slacker.arn
  rule = aws_cloudwatch_event_rule.ecs_change.name
  input_transformer {
    input_paths = {
      task               = "$.detail.taskDefinitionArn",
      status             = "$.detail.lastStatus",
      container_exitcode = "$.detail.containers[0].exitCode",
    }
    input_template = <<EOF
{
  "task": <task>,
  "status": <status>,
  "container_exitcode": <container_exitcode>
}
EOF
  }
}

resource "aws_lambda_permission" "cloudwatch_lambda_perms" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slacker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_change.arn
}

locals {

  name_prefix = "${var.name_prefix}-knimer"

}
