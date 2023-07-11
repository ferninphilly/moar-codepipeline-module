resource "aws_codebuild_project" "typesvalidator" {
  name           = "moar-${var.client}-typesvalidate-build"
  description    = "TF types validation for meta pipeline"
  build_timeout  = "29"
  queued_timeout = "30"

  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = data.aws_ecr_repository.codebuild-image-repo.repository_url
    image_pull_credentials_type = "SERVICE_ROLE"
    privileged_mode             = false
  }

  source {
    type = "CODEPIPELINE"
    buildspec = templatefile("${path.module}/tpls/types-validate-spec.yml", {
      CURRENT_DATE = formatdate("YYYYMMDDhhmm", timestamp())
      CLIENT       = var.client
      GIT_TOKEN    = local.git_token
    })
    report_build_status = true
  }
}
