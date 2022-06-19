resource "aws_codestarconnections_connection" "pipeline_connection" {
  name          = "${var.client}-${var.environment}-cs-cnx"
  provider_type = "GitHub"
}


resource "aws_codepipeline" "moar-typescript-codepipeline" {
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
        BranchName       = var.gitenv
      }
    }
}
  stage {
    name = "Validate"

    action {
      name             = "ValidateTypescriptPackage"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      run_order        = 1
      input_artifacts  = ["SourceArtifact"]

      configuration = {
        ProjectName          = aws_codebuild_project.validator.name
      }
    }
    action {
      name             = "LintTypescript"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      run_order        = 1
      input_artifacts  = ["SourceArtifact"]

      configuration = {
        ProjectName          = aws_codebuild_project.linter.name
      }
    }
    action {
      name             = "TypeScriptBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      run_order        = 1
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = [ "TypescriptBuildArtifact"]

      configuration = {
        ProjectName          = aws_codebuild_project.builder.name
      }
    }
    action {
      name             = "TypeScriptTest"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      run_order        = 1
      input_artifacts  = ["SourceArtifact"]
      configuration = {
        ProjectName          = aws_codebuild_project.tester.name
      }
    }
  }
  stage {
    name = "Deploy"

    action {
      name      = "DeployToNPM"
      category  = "Build"
      owner     = "AWS"
      provider  = "CodeBuild"
      version   = "1"
      run_order = 5

      input_artifacts  = ["TypescriptBuildArtifact"]
      output_artifacts = []

      configuration = {
        ProjectName          = aws_codebuild_project.apply-step.name
        PrimarySource        = "TypescriptBuildArtifact"
      }
    }
  }
}

