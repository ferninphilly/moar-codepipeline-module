output "website_endpoint" {
    description = "This is the website endpoint for the bucket needed by cloudfront"
    value = aws_s3_bucket.moar_website.website_endpoint
}
