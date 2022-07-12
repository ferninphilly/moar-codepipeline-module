/* Null lambda - for removing pipeline stages
 */

resource "aws_iam_role" "iam_for_null_lambda" {
  name_prefix = "iam_for_null_lambda"

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

resource "aws_lambda_function" "null_lambda" {
  // A bit of a hack to allow us to use the same ZIP file everywhere.
  filename      = ".terraform/modules/codepipeline_module/null_lambda_function.zip"
  function_name = "null-${var.client}-${var.environment}"
  role          = aws_iam_role.iam_for_null_lambda.arn
  handler       = "index.js"
  runtime       = "nodejs14.x"
}
