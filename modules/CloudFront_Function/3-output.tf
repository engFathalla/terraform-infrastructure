# Output block for CloudFront function ARNs
output "function_arns" {
  # Description of the output variable.
  description = "ARNs of the CloudFront functions"

  # The value is a list comprehension that extracts the ARN for each CloudFront function created.
  value = [for func in aws_cloudfront_function.cloudfront_function : func.arn]
}

# Output block for CloudFront function event types
output "function_event_types" {
  # Description of the output variable.
  description = "List of event types for CloudFront functions"

  # The value is a list comprehension that extracts the event types from the "cloudfront_functions" variable.
  value = [for func in var.cloudfront_functions : func.event_type]
}
