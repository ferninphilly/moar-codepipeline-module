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
      image                       = aws_ecr_repository.yarn-image-repo.repository_url
      image_pull_credentials_type = "SERVICE_ROLE"
      privileged_mode             = false
    }

    source {
      type     = "CODEPIPELINE"
      location = "https://github.com/${var.repository_owner}/${var.repository_name}.git"
      buildspec = templatefile("${path.module}/tpls/typesvalidatespec.yml", {
        CURRENT_DATE = formatdate("YYYYMMDDhhmm", timestamp())
        CLIENT       = var.client
      })
      report_build_status = true
  }
}