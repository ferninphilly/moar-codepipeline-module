/* Null lambda - for removing pipeline stages
 */

resource "aws_iam_role" "iam_for_null_lambda" {
  name = "iam_for_null_lambda"

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
  filename      = "null_lambda_function.zip"
  function_name = "null_lambda"
  role          = aws_iam_role.iam_for_null_lambda.arn
  handler       = "index.js"
  runtime       = "nodejs14.x"
}
