/* find ECR repo for this branch */

data "aws_ecr_repository" "codebuild-image-repo" {
  name = "moar-codebuild-${var.environment}-image"
}

data "aws_ecr_repository" "codebuild-test-image-repo" {
  name = "moar-codebuild-test-${var.environment}-image"
}
