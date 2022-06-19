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

resource "aws_iam_role" "codepipeline_role" {
  name = "meta_codepipeline_${var.client}_${var.environment}"
  force_detach_policies = true
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "CodePipelineFullAccess" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}

resource "aws_iam_role_policy_attachment" "codepipelineS3FullAccess" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "codepipelineAWSCodeBuildAdminAccess" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}

resource "aws_iam_role_policy_attachment" "codepipelineCloudWatchLogsFullAccess" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}
