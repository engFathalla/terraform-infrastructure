
output "multiple_buckets" {
  value = aws_s3_bucket.multiple_buckets
}
output "s3_distribution" {
  value = aws_cloudfront_distribution.s3_distribution
}
