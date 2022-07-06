/* create ECR repo for this branch */

resource "aws_ecr_repository" "yarn-image-repo" {
  name                 = "moar-${var.client}-client-${var.environment}-yarn-image"
  image_tag_mutability = "IMMUTABLE"
}

/* expire all but 10 latest images */
resource "aws_ecr_lifecycle_policy" "yarn_expire_old_imgs" {
  repository = aws_ecr_repository.yarn-image-repo.name
  policy     = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 10 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 10
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_ecr_repository_policy" "allow_codebuild" {
  repository = aws_ecr_repository.yarn-image-repo.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "Allow Codebuild access",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
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
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

resource "aws_ecr_repository" "terragrunt-image-repo" {
  name = "meta-${var.stack_client}-${var.environment}-terragrunt-base-image"
}

/* expire all but 10 latest images */
resource "aws_ecr_lifecycle_policy" "terragrunt_expire_old_imgs" {
  repository = "meta-${var.stack_client}-${var.environment}-terragrunt-base-image"
  depends_on = [
    aws_ecr_repository.terragrunt-image-repo,
    aws_ecr_repository.yarn-image-repo
  ]
  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 10 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 10
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}
