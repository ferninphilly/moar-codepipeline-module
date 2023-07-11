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
    image                       = data.aws_ecr_repository.codebuild-image-repo.repository_url
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
    buildspec = templatefile("${path.module}/tpls/planspec.yml", {
      TF_DIR       = local.tf_dir
      CURRENT_DATE = formatdate("YYYYMMDDhhmm", timestamp())
      S3BUCKET     = aws_s3_bucket.plans-bucket.id
      CLIENT       = var.client
      GIT_TOKEN    = var.git_token
    })
    report_build_status = true
  }
}



