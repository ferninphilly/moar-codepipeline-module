data "template_file" "buildspec" {
  template = templatefile("${path.module}/tpls/buildspec.yml", {
      NAME = "${var.client}-${var.environment}"
      ENVIRONMENT = var.environment
      CLIENT = var.client
      SLACK_CHANNEL = var.slack_channel
    })
  vars = {
    environment          = var.environment
  }
}

data "template_file" "testspec" {
  template = templatefile("${path.module}/tpls/testspec.yml", {
      NAME = "${var.client}-${var.environment}"
      ENVIRONMENT = var.environment
      CLIENT = var.client
      SLACK_CHANNEL = var.slack_channel
    })
  vars = {
    environment          = var.environment
  }
}

resource "aws_codebuild_project" "static_web_build" {
  badge_enabled  = false
  build_timeout  = 60
  name           = "moar-${var.client}-${var.environment}-codebuild"
  queued_timeout = 480
  service_role   = aws_iam_role.codebuild_role.arn
  tags = {
    Environment = var.environment
  }

  artifacts {
    encryption_disabled    = false
    name                   = aws_s3_bucket.artifacts-bucket.id
    override_artifact_name = false
    packaging              = "NONE"
    type                   = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = aws_ecr_repository.base_image.repository_url
    image_pull_credentials_type = "SERVICE_ROLE"
    privileged_mode             = false
    type                        = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
      group_name = "moar-${var.client}-${var.environment}-build-logs"
    }

    s3_logs {
      encryption_disabled = false
      status              = "ENABLED"
      location            = "${aws_s3_bucket.artifacts-bucket.id}/build-logs/${formatdate("YYYYMMDDhhmm", timestamp())}"
    }
  }

  source {
    buildspec           = data.template_file.buildspec.rendered
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
    type                = "CODEPIPELINE"
  }
}

resource "aws_codebuild_project" "static_web_test_build" {
  badge_enabled  = false
  build_timeout  = 60
  name           = "moar-${var.client}-${var.environment}-build"
  queued_timeout = 480
  service_role   = aws_iam_role.codebuild_role.arn
  tags = {
    Environment = var.environment
  }

  artifacts {
    encryption_disabled    = false
    name                   = aws_s3_bucket.artifacts-bucket.id
    override_artifact_name = false
    packaging              = "NONE"
    type                   = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = aws_ecr_repository.base_image.repository_url
    image_pull_credentials_type = "SERVICE_ROLE"
    privileged_mode             = false
    type                        = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }

    s3_logs {
      encryption_disabled = false
      status              = "DISABLED"
    }
  }

  source {
    buildspec           = data.template_file.testspec.rendered
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
    type                = "CODEPIPELINE"
  }
}

resource "aws_iam_role" "codebuild_role" {
  name = "moar-${var.client}-${var.environment}-codebuild-role"
  force_detach_policies = true
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codebuild_access_policy" {
  name = "moar-${var.client}-${var.environment}-codebuild-access"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Action": [
                "ecr:*"
            ],
          "Effect": "Allow",
          "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AWSCodePipeline_FullAccess" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}

resource "aws_iam_role_policy_attachment" "AWSS3FullAccess" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "codebuildCloudWatchLogsFullAccess" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_access_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_access_policy.arn
}
