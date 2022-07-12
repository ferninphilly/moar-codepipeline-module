resource "aws_codestarconnections_connection" "pipeline_connection" {
  name          = "${var.client}-${var.environment}-cs-cnx"
  provider_type = "GitHub"
}

/* This defines the maximal code pipeline */
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
      name            = "ValidateTypes"
      category        = var.has_autogen_types ? "Test" : "Invoke"
      owner           = "AWS"
      provider        = var.has_autogen_types ? "CodeBuild" : "Lambda"
      version         = "1"
      input_artifacts = var.has_autogen_types ? ["InstalledSourceArtefact"] : []

      configuration = var.has_autogen_types ? {
        ProjectName = aws_codebuild_project.typesvalidator.name
      } : { FunctionName = aws_lambda_function.null_lambda.arn }
    }

    action {
      name            = "Lint"
      category        = var.has_typescript ? "Test" : "Invoke"
      owner           = "AWS"
      provider        = var.has_typescript ? "CodeBuild" : "Lambda"
      version         = "1"
      run_order       = 1
      input_artifacts = var.has_typescript ? ["InstalledSourceArtefact"] : []

      configuration = var.has_typescript ? {
        ProjectName = aws_codebuild_project.linter.name
      } : { FunctionName = aws_lambda_function.null_lambda.arn }
    }

    action {
      name            = "ValidateTerraform"
      category        = var.has_infrastructure ? "Test" : "Invoke"
      owner           = "AWS"
      provider        = var.has_infrastructure ? "CodeBuild" : "Lambda"
      version         = "1"
      run_order       = 1
      input_artifacts = var.has_infrastructure ? ["InstalledSourceArtefact"] : []

      configuration = var.has_infrastructure ? {
        ProjectName = aws_codebuild_project.tfvalidator.name
      } : { FunctionName = aws_lambda_function.null_lambda.arn }

    }

    action {
      name             = "Build"
      category         = var.has_typescript ? "Build" : "Invoke"
      owner            = "AWS"
      provider         = var.has_typescript ? "CodeBuild" : "Lambda"
      version          = "1"
      run_order        = 1
      input_artifacts  = var.has_typescript ? ["InstalledSourceArtefact"] : []
      output_artifacts = var.has_typescript ? ["TypescriptBuildArtifact"] : []

      configuration = var.has_typescript ? {
        ProjectName = aws_codebuild_project.builder.name
      } : { FunctionName = aws_lambda_function.null_lambda.arn }
    }

    action {
      name            = "PredeployTest"
      category        = var.has_predeploy_tests ? "Test" : "Invoke"
      owner           = "AWS"
      provider        = var.has_predeploy_tests ? "CodeBuild" : "Lambda"
      version         = "1"
      run_order       = 1
      input_artifacts = var.has_predeploy_tests ? ["InstalledSourceArtefact"] : []

      configuration = var.has_predeploy_tests ? {
        ProjectName = aws_codebuild_project.tester.name
      } : { FunctionName = aws_lambda_function.null_lambda.arn }
    }
  }

  stage {
    name = "Plan"

    action {
      name             = "TerraformPlan"
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
      } : { FunctionName = aws_lambda_function.null_lambda.arn }
    }
  }

  stage {
    name = "Gate" # TODO: SNS

    action {
      name     = "TerraformPlanApproval"
      category = var.has_infrastructure ? "Approval" : "Invoke"
      owner    = "AWS"
      provider = var.has_infrastructure ? "Manual" : "Lambda"
      version  = "1"
      configuration = var.has_infrastructure ? {
        CustomData = "Check your email to see plan for ${var.client}-${var.environment} and decide whether to approve"
      } : { FunctionName = aws_lambda_function.null_lambda.arn }
    }
  }

  stage {
    name = "Deploy"

    action {
      name     = "TerraformApply"
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
      } : { FunctionName = aws_lambda_function.null_lambda.arn }
    }

    action {
      name     = "PublishToNPM"
      category = var.should_publish ? "Build" : "Invoke"
      owner    = "AWS"
      provider = var.should_publish ? "CodeBuild" : "Lambda"
      version  = "1"

      input_artifacts = var.should_publish ? ["TypescriptBuildArtifact"] : []

      configuration = var.should_publish ? {
        ProjectName   = aws_codebuild_project.publish.name
        PrimarySource = "TypescriptBuildArtifact"
      } : { FunctionName = aws_lambda_function.null_lambda.arn }
    }
  }

  stage {
    name = "Verify"

    action {
      name     = "PostdeployTest"
      category = var.has_postdeploy_tests ? "Test" : "Invoke"
      owner    = "AWS"
      provider = var.has_postdeploy_tests ? "CodeBuild" : "Lambda"
      version  = "1"

      input_artifacts = var.has_postdeploy_tests ? ["InstalledSourceArtefact"] : []

      configuration = var.has_postdeploy_tests ? {
        ProjectName = aws_codebuild_project.postdeploy_tester.name
      } : { FunctionName = aws_lambda_function.null_lambda.arn }
    }
  }
}

