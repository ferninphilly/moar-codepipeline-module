resource "aws_codebuild_project" "tfvalidator" {
  name           = "meta-${var.client}-validator-build"
  description    = "TF validator for meta pipeline"
  build_timeout  = "29"
  queued_timeout = "30"

  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = aws_ecr_repository.base-image-repo.repository_url
    image_pull_credentials_type = "SERVICE_ROLE"
    privileged_mode             = false
  }

  source {
    type = "CODEPIPELINE"
    buildspec = templatefile("${var.buildspec_path}/validate-terraform-spec.yml", {
      TF_DIR       = local.tf_dir
      CURRENT_DATE = formatdate("YYYYMMDDhhmm", timestamp())
      S3BUCKET     = aws_s3_bucket.plans-bucket.id
      CLIENT       = var.client
    })
    report_build_status = true
  }
}

