resource "aws_s3_bucket" "artifacts-bucket" {
  bucket = "moar-${var.client}-${var.environment}-artifacts"
}
