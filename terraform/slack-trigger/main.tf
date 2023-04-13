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
              "ssm:GetParameter"
            ],
            "Resource": ["${var.slack_signing_secret_arn}"]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "execution_role_secret_access" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.secret_access.arn
}

resource "aws_iam_policy" "ecs_access" {
  name = "${local.name_prefix}-lambda-ecs-access-policy"

  tags = {
    Name = "${local.name_prefix}-lambda-ecs-access-policy"
  }

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowPassRole",
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*"
        },
        {
            "Sid": "RunECSTask",
            "Effect": "Allow",
            "Action": [
              "ecs:RunTask"
            ],
            "Resource": ${jsonencode(keys(var.knimer_ecs_tasks))}
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "execution_role_ecs_access" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.ecs_access.arn
}

data "archive_file" "zipped_python" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "slasher" {
  filename         = data.archive_file.zipped_python.output_path
  function_name    = local.lambda_function_name
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.zipped_python.output_base64sha256
  runtime          = "python3.9"
  architectures    = ["x86_64"]
  tags = {
    Name = "${local.name_prefix}-lambda"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy_attachment.execution_role_ecs_access,
    aws_iam_role_policy_attachment.execution_role_secret_access,
    aws_cloudwatch_log_group.lambda,
  ]

  environment {
    variables = {
      SLACK_SIGNING_SECRET_NAME = var.slack_signing_secret_name
      REGION_NAME               = var.aws_region
      ECS_SUBNETS               = join(",", var.ecs_subnets)
      SLACK_CHANNEL_RESTRICTION = var.slack_channel_restriction
      ECS_TASKS                 = jsonencode(var.knimer_ecs_tasks)
    }
  }
}

resource "aws_apigatewayv2_api" "lambda" {
  name          = "${local.name_prefix}-gw"
  protocol_type = "HTTP"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 7
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "v1"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.slasher.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST ${local.path}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slasher.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

# Logging
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = 7
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name = "${local.name_prefix}-lambda-logging"

  tags = {
    Name = "${local.name_prefix}-lambda-logging"
  }

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

locals {

  name_prefix          = "${var.name_prefix}-knimer-slash"
  lambda_function_name = "${local.name_prefix}-lambda"
  path                 = "/knimer"

}
