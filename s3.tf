#Artifacts bucket
resource "aws_s3_bucket" "artifacts-bucket" {
  bucket = "meta-artifacts-${var.stack_client}-${var.environment}-bucket"
}

resource "aws_s3_bucket" "plans-bucket" {
  bucket = "meta-tf-plans-${var.stack_client}-${var.environment}-bucket"
}

