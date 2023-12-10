# Output block for multiple buckets
output "multiple_buckets" {
  value = aws_s3_bucket.multiple_buckets
}

# Output block for CloudFront distribution
output "s3_distribution" {
  value = aws_cloudfront_distribution.s3_distribution
}
