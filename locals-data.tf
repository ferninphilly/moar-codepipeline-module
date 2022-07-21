# constructs default values from the vars, and pulls secrets

data "aws_secretsmanager_secret_version" "config" {
  secret_id = "deployment/config"
}


locals {
  tf_dir              = "infrastructure/${var.environment}"
  config_data         = jsondecode(data.aws_secretsmanager_secret_version.config.secret_string)
  github_secret_token = local.config_data["git_token"]
  slack_channel       = local.config_data["slack_channel"]
  sns_error_topic_arn = var.sns_error_topic_arn == "" ? "arn:aws:sns:${var.region}:${var.account_id}:moar-${var.environment}-sns-error-topic" : var.sns_error_topic_arn
}
