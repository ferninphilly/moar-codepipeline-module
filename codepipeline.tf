resource "aws_codestarconnections_connection" "pipeline_connection" {
  name          = "${var.client}-${var.environment}-cs-cnx"
  provider_type = "GitHub"
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
        ConnectionArn    = aws_codestarconnections_connection.pipeline_connection.arn
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
      output_artifacts = ["InstalledSourceArtefact"]

      configuration = {
        ProjectName = aws_codebuild_project.installer.name
      }
    }
  }

  stage {
    name = "Validate"

    action {
      name            = var.has_autogen_types ? "ValidateTypes" : "noneA"
      category        = var.has_autogen_types ? "Test" : "Invoke"
      owner           = "AWS"
      provider        = var.has_autogen_types ? "CodeBuild" : "Lambda"
      version         = "1"
      input_artifacts = var.has_autogen_types ? ["InstalledSourceArtefact"] : []

      configuration = var.has_autogen_types ? {
        ProjectName = aws_codebuild_project.typesvalidator.name
      } : { FunctionName = aws_lambda_function.null_lambda.function_name }
    }

    action {
      name            = var.has_typescript ? "Lint" : "noneB"
      category        = var.has_typescript ? "Test" : "Invoke"
      owner           = "AWS"
      provider        = var.has_typescript ? "CodeBuild" : "Lambda"
      version         = "1"
      run_order       = 1
      input_artifacts = var.has_typescript ? ["InstalledSourceArtefact"] : []

      configuration = var.has_typescript ? {
        ProjectName = aws_codebuild_project.linter.name
      } : { FunctionName = aws_lambda_function.null_lambda.function_name }
    }

    action {
      name            = var.has_infrastructure ? "ValidateTerraform" : "noneC"
      category        = var.has_infrastructure ? "Test" : "Invoke"
      owner           = "AWS"
      provider        = var.has_infrastructure ? "CodeBuild" : "Lambda"
      version         = "1"
      run_order       = 1
      input_artifacts = var.has_infrastructure ? ["InstalledSourceArtefact"] : []

      configuration = var.has_infrastructure ? {
        ProjectName = aws_codebuild_project.tfvalidator.name
      } : { FunctionName = aws_lambda_function.null_lambda.function_name }

    }

    action {
      name             = var.has_typescript ? "Build" : "noneD"
      category         = var.has_typescript ? "Build" : "Invoke"
      owner            = "AWS"
      provider         = var.has_typescript ? "CodeBuild" : "Lambda"
      version          = "1"
      run_order        = 1
      input_artifacts  = var.has_typescript ? ["InstalledSourceArtefact"] : []
      output_artifacts = var.has_typescript ? ["TypescriptBuildArtifact"] : []

      configuration = var.has_typescript ? {
        ProjectName = aws_codebuild_project.builder.name
      } : { FunctionName = aws_lambda_function.null_lambda.function_name }
    }

    action {
      name            = var.has_predeploy_tests ? "PredeployTest" : "noneE"
      category        = var.has_predeploy_tests ? "Test" : "Invoke"
      owner           = "AWS"
      provider        = var.has_predeploy_tests ? "CodeBuild" : "Lambda"
      version         = "1"
      run_order       = 1
      input_artifacts = var.has_predeploy_tests ? ["InstalledSourceArtefact"] : []

      configuration = var.has_predeploy_tests ? {
        ProjectName = aws_codebuild_project.tester.name
      } : { FunctionName = aws_lambda_function.null_lambda.function_name }
    }
  }

  stage {
    name = "Plan"

    action {
      name             = var.has_infrastructure ? "TerraformPlan" : "noneF"
      category         = var.has_infrastructure ? "Build" : "Invoke"
      owner            = "AWS"
      provider         = var.has_infrastructure ? "CodeBuild" : "Lambda"
      version          = "1"
      run_order        = 1
      input_artifacts  = var.has_infrastructure ? [var.has_typescript ? "TypescriptBuildArtifact" : "InstalledSourceArtefact"] : []
      output_artifacts = ["TerraformPlanArtifact"]

      configuration = var.has_infrastructure ? {
        ProjectName          = aws_codebuild_project.planner.name
        EnvironmentVariables = "[{\"name\":\"TF_ACTION\",\"value\":\"plan\",\"type\":\"PLAINTEXT\"}]"
      } : { FunctionName = aws_lambda_function.null_lambda.function_name }
    }
  }

  stage {
    name = "Gate" # TODO: SNS

    action {
      name     = var.has_infrastructure ? "TerraformPlanApproval" : "noneG"
      category = var.has_infrastructure ? "Approval" : "Invoke"
      owner    = "AWS"
      provider = var.has_infrastructure ? "Manual" : "Lambda"
      version  = "1"
      configuration = var.has_infrastructure ? {
        CustomData = "Check your email to see plan for ${var.client}-${var.environment} and decide whether to approve"
      } : { FunctionName = aws_lambda_function.null_lambda.function_name }
    }
  }

  stage {
    name = "Deploy"

    action {
      name     = var.has_infrastructure ? "TerraformApply" : "noneH"
      category = var.has_infrastructure ? "Build" : "Invoke"
      owner    = "AWS"
      provider = var.has_infrastructure ? "CodeBuild" : "Lambda"
      version  = "1"

      input_artifacts  = var.has_infrastructure ? ["TerraformPlanArtifact"] : []
      output_artifacts = []

      configuration = var.has_infrastructure ? {
        ProjectName          = aws_codebuild_project.apply-step.name
        PrimarySource        = "TerraformPlanArtifact"
        EnvironmentVariables = "[{\"name\":\"TF_ACTION\",\"value\":\"apply\",\"type\":\"PLAINTEXT\"}]"
      } : { FunctionName = aws_lambda_function.null_lambda.function_name }
    }

    action {
      name     = var.should_publish ? "PublishToNPM" : "noneI"
      category = var.should_publish ? "Build" : "Invoke"
      owner    = "AWS"
      provider = var.should_publish ? "CodeBuild" : "Lambda"
      version  = "1"

      input_artifacts = var.should_publish ? ["TypescriptBuildArtifact"] : []

      configuration = var.should_publish ? {
        ProjectName   = aws_codebuild_project.publish.name
        PrimarySource = "TypescriptBuildArtifact"
      } : { FunctionName = aws_lambda_function.null_lambda.function_name }
    }
  }

  stage {
    name = "Verify"

    action {
      name     = var.has_postdeploy_tests ? "PostdeployTest" : "noneJ"
      category = var.has_postdeploy_tests ? "Test" : "Invoke"
      owner    = "AWS"
      provider = var.has_postdeploy_tests ? "CodeBuild" : "Lambda"
      version  = "1"

      input_artifacts = var.has_postdeploy_tests ? ["InstalledSourceArtefact"] : []

      configuration = var.has_postdeploy_tests ? {
        ProjectName = aws_codebuild_project.postdeploy_tester.name
      } : { FunctionName = aws_lambda_function.null_lambda.function_name }
    }
  }
}

