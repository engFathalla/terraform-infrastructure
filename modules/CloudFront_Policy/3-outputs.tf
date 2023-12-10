# Output block for ETag values of CloudFront cache policies
output "etag" {
  description = "ETag values of CloudFront cache policies"
  value       = [for policy in aws_cloudfront_cache_policy.this : policy.etag]
}

# Output block for ID values of CloudFront cache policies
output "id" {
  description = "ID values of CloudFront cache policies"
  value       = [for policy in aws_cloudfront_cache_policy.this : policy.id]
}
