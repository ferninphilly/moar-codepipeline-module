locals {
  source_vers = {
    "dev": "develop",
    "uat": "uat",
    "prod": "main",
  }
}

resource "aws_codestarconnections_connection" "pipeline_connection" {
  name          = "${var.client}-${var.environment}-cs-cnx"
  provider_type = "GitHub"
}


resource "aws_codepipeline" "static_web_pipeline" {
  name     = "moar-${var.client}-${var.environment}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  tags     = {
    Environment = var.environment
  }

  artifact_store {
    location = var.artifacts_bucket_name
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.pipeline_connection.arn
        FullRepositoryId = "${var.repository_owner}/${var.repository_name}"
        BranchName       = local.source_vers[var.environment]
      }
    }
}
#   stage {
#     name = "Test"

#     action {
#       category = "Test"
#       configuration = {
#         "EnvironmentVariables" = jsonencode(
#           [
#             {
#               name  = "environment"
#               type  = "PLAINTEXT"
#               value = var.environment
#             },
#           ]
#         )
#         "ProjectName" = aws_codebuild_project.static_web_test_build.id
#       }
#       input_artifacts = [
#         "SourceArtifact",
#       ]
#       name = "Test"
#       # output_artifacts = [
#       #   "TestArtifact",
#       # ]
#       owner     = "AWS"
#       provider  = "CodeBuild"
#       run_order = 1
#       version   = "1"
#     }
#   }
  stage {
    name = "Build"

    action {
      category = "Build"
      configuration = {
        "EnvironmentVariables" = jsonencode(
          [
            {
              name  = "environment"
              type  = "PLAINTEXT"
              value = var.environment
            },
          ]
        )
        "ProjectName" = aws_codebuild_project.static_web_build.id
      }
      input_artifacts = [
        "SourceArtifact",
      ]
      name = "Build"
      output_artifacts = [
        "BuildArtifact",
      ]
      owner     = "AWS"
      provider  = "CodeBuild"
      run_order = 1
      version   = "1"
    }
  }
  stage {
    name = "Deploy"

    action {
      category = "Deploy"
      configuration = {
        "BucketName" = aws_s3_bucket.moar_website.id  
        "Extract"    = "true"
      }
      input_artifacts = [
        "BuildArtifact",
      ]
      name             = "Deploy"
      output_artifacts = []
      owner            = "AWS"
      provider         = "S3"
      run_order        = 1
      version          = "1"
    }
  }
}

