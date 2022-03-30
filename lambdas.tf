module "slack_notify" {
  source   = "git::https://github.com/ferninphilly/moar-lambda-module.git"
  stack_name                               = "${var.client}-${var.environment}"
  lambda_function_description              = "${var.client} lambda to notify slack on pushes"
  lambda_binary_name                       = "moar-send-slack-notifications"
  # This is likely to result in fatal name conflicts, in which case I will revert this commit
  lambda_function_name                     = "moar-send-slack-notifications"
  lambda_function_source_base_path         = "${path.module}/lambdas_code"
  lambda_function_existing_execute_role    = aws_iam_role.slack_notify_lambda_role.arn
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

resource "aws_iam_role" "slack_notify_lambda_role" {
    inline_policy {
        name = "slack_notify_lambda_role_policy"
        policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:*"
            ]
        }
    ]
}
EOF
    }
    assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
    {
    "Effect": "Allow",
    "Principal": {
        "Service": "lambda.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
    }
]
}
EOF
}
