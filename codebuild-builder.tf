resource "aws_codebuild_project" "builder" {
  name           = "moar-${var.client}-builder-build"
  description    = "Typescript builder for moar pipeline"
  build_timeout  = "29"
  queued_timeout = "30"

  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_LARGE"
    image                       = data.aws_ecr_repository.codebuild-image-repo.repository_url
    image_pull_credentials_type = "SERVICE_ROLE"
    privileged_mode             = false

    environment_variable {
      name  = "TF_ACTION"
      value = "plan"
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
      type  = "PLAINTEXT"
    }

  }

  source {
    type = "CODEPIPELINE"
    buildspec = templatefile("${path.module}/tpls/buildspec.yml", {
      TF_DIR       = local.tf_dir
      CURRENT_DATE = formatdate("YYYYMMDDhhmm", timestamp())
      CLIENT       = var.client
    })
    report_build_status = true
  }
}
