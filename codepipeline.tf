data "aws_codestarconnections_connection" "pipeline_connection" {
  name = var.repository_owner == "codicesinteractive" ? "codicesinteractive" : "codepipeline-connection" /* second of these created in the common-infrastructure folder */
}

/* This defines the maximal code pipeline */
resource "aws_codepipeline" "moar-codepipeline" {
  name     = "deploy-${var.client}-${var.environment}-codepipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.artifacts-bucket.id
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
        ConnectionArn    = data.aws_codestarconnections_connection.pipeline_connection.arn
        FullRepositoryId = "${var.repository_owner}/${var.repository_name}"
        BranchName       = var.gitenv == "" ? var.environment : var.gitenv
      }
    }
  }

  stage {
    name = "Install"

    /* It's safe to install every time, as it looks for package.json files and only runs installs when it finds them */
    action {
      name             = "Install"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["InstalledSourceArtifact"]

      configuration = {
        ProjectName = aws_codebuild_project.installer.name
      }
    }
  }

  stage {
    name = "Validate"

    dynamic "action" {
      for_each = var.has_autogen_types ? ["1"] : []
      content {
        name            = "ValidateTypes"
        category        = "Test"
        owner           = "AWS"
        provider        = "CodeBuild"
        version         = "1"
        input_artifacts = ["InstalledSourceArtifact"]

        configuration = { ProjectName = aws_codebuild_project.typesvalidator.name }
      }
    }

    dynamic "action" {
      for_each = var.has_typescript ? ["1"] : []
      content {
        name            = "Lint"
        category        = "Test"
        owner           = "AWS"
        provider        = "CodeBuild"
        version         = "1"
        run_order       = 1
        input_artifacts = ["InstalledSourceArtifact"]

        configuration = { ProjectName = aws_codebuild_project.linter.name }
      }
    }

    dynamic "action" {
      for_each = var.has_infrastructure ? ["1"] : []
      content {
        name            = "ValidateTerraform"
        category        = "Test"
        owner           = "AWS"
        provider        = "CodeBuild"
        version         = "1"
        run_order       = 1
        input_artifacts = ["InstalledSourceArtifact"]

        configuration = {
          ProjectName = aws_codebuild_project.tfvalidator.name
        }

      }
    }
    dynamic "action" {
      for_each = (length(var.website_bucket_name) > 0 || var.has_typescript) ? ["1"] : []
      content {
        name             = "Build"
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        version          = "1"
        run_order        = 1
        input_artifacts  = ["InstalledSourceArtifact"]
        output_artifacts = ["BuildArtifact", "BuildDistArtifact"]

        configuration = {
          ProjectName = aws_codebuild_project.builder.name
        }
      }
    }

    dynamic "action" {
      for_each = var.has_predeploy_tests ? ["1"] : []
      content {
        name            = "PredeployTest"
        category        = "Test"
        owner           = "AWS"
        provider        = "CodeBuild"
        version         = "1"
        run_order       = 1
        input_artifacts = ["InstalledSourceArtifact"]

        configuration = {
          ProjectName = aws_codebuild_project.tester.name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.has_infrastructure ? ["1"] : []
    content {
      name = "Plan"

      action {
        name             = "TerraformPlan"
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        version          = "1"
        run_order        = 1
        input_artifacts  = var.has_typescript ? "BuildArtifact" : "InstalledSourceArtifact"
        output_artifacts = ["TerraformPlanArtifact"]

        configuration = {
          ProjectName          = aws_codebuild_project.planner.name
          EnvironmentVariables = "[{\"name\":\"TF_ACTION\",\"value\":\"plan\",\"type\":\"PLAINTEXT\"}]"
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.has_infrastructure ? ["1"] : []
    content {
      name = "Gate" # TODO: SNS

      action {
        name     = "TerraformPlanApproval"
        category = "Approval"
        owner    = "AWS"
        provider = "Manual"
        version  = "1"
        configuration = {
          CustomData = "Check your email to see plan for ${var.client}-${var.environment} and decide whether to approve"
        }
      }
    }
  }

  stage {
    name = "Deploy"

    dynamic "action" {
      for_each = var.has_infrastructure ? ["1"] : []
      content {
        name     = "TerraformApply"
        category = "Build"
        owner    = "AWS"
        provider = "CodeBuild"
        version  = "1"

        input_artifacts  = ["TerraformPlanArtifact"]
        output_artifacts = []

        configuration = {
          ProjectName          = aws_codebuild_project.apply-step.name
          PrimarySource        = "TerraformPlanArtifact"
          EnvironmentVariables = "[{\"name\":\"TF_ACTION\",\"value\":\"apply\",\"type\":\"PLAINTEXT\"}]"
        }
      }
    }
    dynamic "action" {
      for_each = var.should_publish ? ["1"] : []
      content {
        name     = "PublishToNPM"
        category = "Build"
        owner    = "AWS"
        provider = "CodeBuild"
        version  = "1"

        input_artifacts = ["BuildArtifact"]

        configuration = {
          ProjectName   = aws_codebuild_project.publish.name
          PrimarySource = "BuildArtifact"
        }
      }
    }

    dynamic "action" {
      for_each = length(var.website_bucket_name) > 0 ? ["1"] : []
      content {
        name     = "DeployWebsite"
        category = "Deploy"
        configuration = {
          "BucketName" = var.website_bucket_name
          "Extract"    = "true"
        }
        input_artifacts = [
          "BuildDistArtifact",
        ]
        output_artifacts = []
        owner            = "AWS"
        provider         = "S3"
        run_order        = 1
        version          = "1"
      }
    }
  }

  dynamic "stage" {
    for_each = var.has_postdeploy_tests ? ["1"] : []
    content {
      name = "Verify"

      action {
        name     = "PostdeployTest"
        category = "Test"
        owner    = "AWS"
        provider = "CodeBuild"
        version  = "1"

        input_artifacts = ["InstalledSourceArtifact"]

        configuration = {
          ProjectName = aws_codebuild_project.postdeploy_tester.name
        }
      }
    }
  }
}

