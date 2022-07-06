resource "aws_codebuild_project" "deploy" {
  name           = "moar-${var.client}-deployer-build"
  description    = "Typescript deployer for moar pipeline"
  build_timeout  = "29"
  queued_timeout = "30"

  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = aws_ecr_repository.yarn-image-repo.repository_url
    image_pull_credentials_type = "SERVICE_ROLE"
    privileged_mode             = false
  }

  source {
    type = "CODEPIPELINE"
    buildspec = templatefile("${path.module}/tpls/publishspec.yml", {
      ENVIRONMENT = var.environment
      CLIENT      = var.client
    })
    report_build_status = true
  }
}
