resource "aws_codestarconnections_connection" "common" {
  name          = "codepipeline-connection"
  provider_type = "GitHub"
}
