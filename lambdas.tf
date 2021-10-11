module "slack_notify" {
  source   = "git::https://github.com/ferninphilly/moar-lambda-module.git"
  stack_name                               = "${var.client}-${var.environment}"
  lambda_function_description              = "${var.client} lambda to notify slack on pushes"
  lambda_binary_name                       = "moar-send-slack-notifications"
  lambda_function_name                     = "moar-send-slack-notifications-${var.client}"
  lambda_function_source_base_path         = "${path.module}/lambdas_code"
  lambda_function_existing_execute_role    = "arn:aws:iam::${var.account_id}:role/service-role/execute_lambda"
  lambda_function_env_vars = {
      WEBHOOK_URL = var.slack_channel,
      STARTED_GIF = var.slack_gifs["STARTED_GIF"],
      SUCCEEDED_GIF = var.slack_gifs["SUCCEEDED_GIF"],
      FAILED_GIF = var.slack_gifs["FAILED_GIF"],
      CANCELLED_GIF = var.slack_gifs["CANCELLED_GIF"]
  }
  client              = var.client
  sns_error_topic_arn = var.sns_error_topic_arn
  environment         = var.environment
  region              = var.region
  account_id          = var.account_id
}

resource "aws_lambda_permission" "cloudwatch_trigger_lambda" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = module.slack_notify.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.codepipeline-notification.arn
}