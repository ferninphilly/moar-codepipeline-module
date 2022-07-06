resource "aws_codebuild_project" "planner" {
  name           = "meta-${var.client}-planner-build"
  description    = "TF planner for meta pipeline"
  build_timeout  = "29"
  queued_timeout = "30"

  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = aws_ecr_repository.base-image-repo.repository_url
    image_pull_credentials_type = "SERVICE_ROLE"
    privileged_mode             = false

    environment_variable {
      name  = "TF_ACTION"
      value = "plan"
      type  = "PLAINTEXT"
    }
  }

  source {
    type     = "CODEPIPELINE"
    location = "https://github.com/ferninphilly/moar-platform-infrastructure.git"
    buildspec = templatefile("${var.buildspec_path}/planspec.yml", {
      TF_DIR       = local.tf_dir
      CURRENT_DATE = formatdate("YYYYMMDDhhmm", timestamp())
      S3BUCKET     = aws_s3_bucket.plans-bucket.id
      CLIENT       = var.client
    })
    report_build_status = true
  }
}

resource "aws_iam_role" "codebuild_role" {
  name                  = "codebuild_${var.client}"
  force_detach_policies = true
  assume_role_policy    = <<EOF
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
  name = "codebuild-access-for-ecr-${var.client}-${var.environment}"

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

resource "aws_iam_policy" "codebuild_access_s3_policy" {
  name = "codebuild-access-for-s3-${var.client}-${var.environment}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Action": [
                "s3:*"
            ],
          "Effect": "Allow",
          "Resource": "arn:aws:s3:::${var.environment}-moar-platform-tfstate"
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

resource "aws_iam_role_policy_attachment" "codebuild_access_s3_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_access_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "codebuildDynamoDBFullAccess" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "codebuildIamFullAccess" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_role_policy_attachment" "codebuildRoute53FullAccess" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}

resource "aws_iam_role_policy_attachment" "codebuildAdminAccess" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


