/* Null lambda - for removing pipeline stages
 */

resource "null_resource" "null_lambda_install" {
  provisioner "local-exec" {
    command = "yarn install --cwd ${path.module}/null-lambda-function"
  }
}

data "archive_file" "null_lambda" {
  type        = "zip"
  output_path = "${path.module}/null_lambda.zip"

  source_dir = "null-lambda-function"
  depends_on = [
    null_resource.null_lambda_install
  ]
}

resource "aws_lambda_function" "null_lambda" {
  // A bit of a hack to allow us to use the same ZIP file everywhere.
  filename      = data.archive_file.null_lambda.output_path
  function_name = "null-${var.client}-${var.environment}"
  role          = aws_iam_role.iam_for_null_lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"
}


resource "aws_iam_role" "iam_for_null_lambda" {
  name = "null-${var.client}-${var.environment}-role"

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
  policy_arn = aws_iam_policy.null_lambda.arn
}

resource "aws_iam_policy" "null_lambda" {
  name = "null-${var.client}-${var.environment}-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "codepipeline:PutJobSuccessResult",
          "codepipeline:PutJobFailureResult"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}
