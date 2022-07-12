/* find ECR repo for this branch */

data "aws_ecr_repository" "codebuild-image-repo" {
  name = "moar-codebuild-${var.environment}-image"
}
