/* Null lambda - for removing pipeline stages
 */

resource "aws_lambda_function" "null_lambda" {
  // A bit of a hack to allow us to use the same ZIP file everywhere.
  filename      = ".terraform/modules/codepipeline_module/null_lambda_function.zip"
  function_name = "null-${var.client}-${var.environment}"
  role          = aws_iam_role.iam_for_null_lambda.arn
  handler       = "index.js"
  runtime       = "nodejs14.x"
}


resource "aws_iam_role" "iam_for_null_lambda" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policy_for_null_lambda" {
  role       = aws_iam_role.iam_for_null_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}