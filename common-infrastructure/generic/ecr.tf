/* create ECR repo for this branch */
resource "aws_ecr_repository" "image-repo" {
  name                 = "moar-codebuild-${var.environment}-image"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository" "test-image-repo" {
  name                 = "moar-codebuild-test-${var.environment}-image"
  image_tag_mutability = "MUTABLE"
}

/* expire all but 10 latest images */
resource "aws_ecr_lifecycle_policy" "expire_old_imgs" {
  for_each   = toset([aws_ecr_repository.image-repo.name, aws_ecr_repository.test-image-repo.name])
  repository = each.key
  policy = jsonencode(
    {
      "rules" : [
        {
          "rulePriority" : 1,
          "description" : "Keep last 10 images",
          "selection" : {
            "tagStatus" : "any",
            "countType" : "imageCountMoreThan",
            "countNumber" : 10
          },
          "action" : {
            "type" : "expire"
          }
        }
      ]
  })
}

resource "aws_ecr_repository_policy" "allow_codebuild" {
  for_each   = toset([aws_ecr_repository.image-repo.name, aws_ecr_repository.test-image-repo.name])
  repository = each.key

  policy = jsonencode(
    {
      "Version" : "2008-10-17",
      "Statement" : [
        {
          "Sid" : "Allow Codebuild access",
          "Effect" : "Allow",
          "Principal" : "*",
          "Action" : [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:DescribeRepositories",
            "ecr:GetRepositoryPolicy",
            "ecr:ListImages",
            "ecr:DeleteRepository",
            "ecr:BatchDeleteImage",
            "ecr:SetRepositoryPolicy",
            "ecr:DeleteRepositoryPolicy",
            "secretsmanager:GetSecretValue"
          ]
        }
      ]
  })

}
