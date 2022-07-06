resource "aws_codestarconnections_connection" "pipeline_connection" {
  name          = "${var.client}-${var.environment}-cs-cnx"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "moar-codepipeline" {
  name     = "meta-${var.client}-${var.environment}-codepipeline"
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
      run_order        = 1
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.pipeline_connection.arn
        FullRepositoryId = "${var.repository_owner}/${var.repository_name}"
        BranchName       = var.gitenv == "" ? var.environment : var.gitenv
      }
    }
  }
  stage {
    name = "Install"

    action {
      name             = "Install"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      run_order        = 1
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["InstalledSourceArtefact"]

      configuration = {
        ProjectName = aws_codebuild_project.installer.name
      }
    }
  }
  stage {
    name = "Validate"
    action {
      count           = var.has_autogen_types ? 1 : 0
      name            = "ValidateTypes"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      run_order       = 1
      input_artifacts = ["InstalledSourceArtefact"]

      configuration = {
        ProjectName = aws_codebuild_project.typesvalidator.name
      }
    }
    action {
      count           = var.has_typescript ? 1 : 0
      name            = "Lint"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      run_order       = 1
      input_artifacts = ["InstalledSourceArtefact"]

      configuration = {
        ProjectName = aws_codebuild_project.linter.name
      }
    }
    action {
      count           = var.has_infrastructure ? 1 : 0
      name            = "ValidateTerraform"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      run_order       = 1
      input_artifacts = ["InstalledSourceArtifact"]

      configuration = {
        ProjectName = aws_codebuild_project.tfvalidator.name
      }
    }
    action {
      count            = var.has_typescript ? 1 : 0
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      run_order        = 1
      input_artifacts  = ["InstalledSourceArtefact"]
      output_artifacts = ["TypescriptBuildArtifact"]

      configuration = {
        ProjectName = aws_codebuild_project.builder.name
      }
    }
    action {
      count           = var.has_predeploy_tests ? 1 : 0
      name            = "Predeploy Test"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      run_order       = 1
      input_artifacts = ["InstalledSourceArtefact"]
      configuration = {
        ProjectName = aws_codebuild_project.tester.name
      }
    }
  }
  stage {
    name  = "Plan"
    count = var.has_infrastructure ? 1 : 0

    action {
      name             = "TerraformPlan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      run_order        = 1
      input_artifacts  = [var.has_typescript ? "TypescriptBuildArtifact" : "InstalledSourceArtefact"]
      output_artifacts = ["TerraformPlanArtifact"]

      configuration = {
        ProjectName          = aws_codebuild_project.planner.name
        EnvironmentVariables = "[{\"name\":\"TF_ACTION\",\"value\":\"plan\",\"type\":\"PLAINTEXT\"}]"
      }
    }
  }

  stage {
    name  = "Gate" # TODO: SNS
    count = var.has_infrastructure ? 1 : 0

    action {
      name      = "TerraformPlanApproval"
      category  = "Approval"
      owner     = "AWS"
      provider  = "Manual"
      version   = "1"
      run_order = 1
      configuration = {
        CustomData = "Check your email to see plan for ${var.client}-${var.environment} and decide whether to approve"
        //"NotificationArn" = aws_sns_topic.terragrunt-plan-topic.arn
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      count     = var.has_infrastructure ? 1 : 0
      name      = "TerraformApply"
      category  = "Build"
      owner     = "AWS"
      provider  = "CodeBuild"
      version   = "1"
      run_order = 5

      input_artifacts  = ["TerraformPlanArtifact"]
      output_artifacts = []

      configuration = {
        ProjectName          = aws_codebuild_project.apply-step.name
        PrimarySource        = "TerraformPlanArtifact"
        EnvironmentVariables = "[{\"name\":\"TF_ACTION\",\"value\":\"apply\",\"type\":\"PLAINTEXT\"}]"
      }
    }

    action {
      count     = var.should_publish ? 1 : 0
      name      = "PublishToNPM"
      category  = "Build"
      owner     = "AWS"
      provider  = "CodeBuild"
      version   = "1"
      run_order = 5

      input_artifacts  = ["TypescriptBuildArtifact"]
      output_artifacts = []

      configuration = {
        ProjectName   = aws_codebuild_project.deploy.name
        PrimarySource = "TypescriptBuildArtifact"
      }
    }

  }

  stage {
    name  = "Verify"
    count = var.has_postdeploy_tests ? 1 : 0

    action {

    }
  }
}

