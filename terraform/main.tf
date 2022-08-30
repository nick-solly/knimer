module "secrets" {
  source           = "./secrets"
  name_prefix      = var.name_prefix
  workflow_secrets = var.workflow_secrets
}

module "roles" {
  source                     = "./roles"
  name_prefix                = var.name_prefix
  s3_bucket_name             = var.s3_bucket_name
  workflow_secrets_value_arn = module.secrets.workflow_secrets_value_arn
}

module "ecs" {
  source                     = "./ecs"
  aws_region                 = var.aws_region
  cpu                        = var.cpu
  memory                     = var.memory
  execution_role_arn         = module.roles.execution_role_arn
  knime_workflow_file        = var.knime_workflow_file
  name_prefix                = var.name_prefix
  s3_bucket_name             = var.s3_bucket_name
  task_role_arn              = module.roles.task_role_arn
  workflow_secrets_value_arn = module.secrets.workflow_secrets_value_arn
  workflow_variables         = var.workflow_variables
}

module "slack" {
  source                       = "./slack"
  count                        = var.slack_webhook_url_secret_arn == "" ? 0 : 1
  name_prefix                  = var.name_prefix
  slack_webhook_url_secret_arn = var.slack_webhook_url_secret_arn
  aws_region                   = var.aws_region
  cluster_arn                  = module.ecs.cluster_arn
}
