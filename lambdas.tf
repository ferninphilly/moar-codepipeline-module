module "slack_notify" {
  source                                = "git::https://github.com/ferninphilly/moar-lambda-module.git"
  stack_name                            = "${var.client}-${var.environment}"
  lambda_function_description           = "${var.client} lambda to notify slack on pushes"
  lambda_binary_name                    = "moar-send-slack-notifications"
  lambda_function_handler               = "moar-send-slack-notifications.handler"
  lambda_function_name                  = "moar-send-slack-notifications-${var.client}"
  lambda_function_source_base_path      = "${path.module}/lambdas_code"
  lambda_function_existing_execute_role = aws_iam_role.slack_notify_lambda_role.arn
  lambda_function_env_vars = {
    WEBHOOK_URL   = local.slack_channel,
    STARTED_GIF   = var.slack_gifs["STARTED"],
    SUCCEEDED_GIF = var.slack_gifs["SUCCEEDED"],
    FAILED_GIF    = var.slack_gifs["FAILED"],
    CANCELLED_GIF = var.slack_gifs["CANCELLED"]
  }
  client              = var.client
  sns_error_topic_arn = local.sns_error_topic_arn
  environment         = var.environment
  region              = var.region
  account_id          = var.account_id
}

module "merge_branches" {
  count = length(var.automerge_to) > 0 ? 1 : 0

  source                                = "git::https://github.com/ferninphilly/moar-lambda-module.git"
  stack_name                            = "${var.client}-${var.environment}"
  lambda_function_description           = "${var.client} lambda to merge branches upon successful pipeline run"
  lambda_binary_name                    = "moar-merge-branches"
  lambda_function_handler               = "moar-merge-branches.handler"
  lambda_function_name                  = "moar-merge-branches-${var.client}"
  lambda_function_source_base_path      = "${path.module}/lambdas_code"
  lambda_function_env_vars              = {}
  run_yarn_install                      = true
  lambda_function_existing_execute_role = aws_iam_role.merge_branches_lambda_role[0].arn
  client                                = var.client
  sns_error_topic_arn                   = local.sns_error_topic_arn
  environment                           = var.environment
  region                                = var.region
  account_id                            = var.account_id
}

resource "aws_lambda_permission" "cloudwatch_trigger_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.slack_notify.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.codepipeline-notification.arn
}

resource "aws_iam_role" "slack_notify_lambda_role" {
  inline_policy {
    name = "slack_notify_lambda_role_policy"
    policy = jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Effect" : "Allow",
            "Action" : "logs:CreateLogGroup",
            "Resource" : "arn:aws:logs:*"
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource" : [
              "arn:aws:logs:*"
            ]
          }
        ]
    })
  }
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "lambda.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
  })
}

resource "aws_iam_role" "merge_branches_lambda_role" {
  count = length(var.automerge_to) > 0 ? 1 : 0

  inline_policy {
    name = "merge_branches_lambda_role_policy"
    policy = jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Effect" : "Allow",
            "Action" : "logs:CreateLogGroup",
            "Resource" : "arn:aws:logs:*"
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource" : [
              "arn:aws:logs:*"
            ]
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "secretsmanager:GetSecretValue"
            ],
            "Resource" : [
              "arn:aws:secretsmanager:*:*:secret:deployment/config*"
            ]
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "codepipeline:PutJobSuccessResult",
              "codepipeline:PutJobFailureResult"
            ],
            "Resource" : [
              "*"
            ]
          },


        ]
    })
  }
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "lambda.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
  })
}
