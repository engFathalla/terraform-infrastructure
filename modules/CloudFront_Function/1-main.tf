# Define an AWS CloudFront function resource.
resource "aws_cloudfront_function" "cloudfront_function" {

  # Use the "for_each" meta-argument to create multiple instances of the CloudFront function based on the elements in the "cloudfront_functions" variable.
  for_each = { for idx, func in var.cloudfront_functions : idx => func }

  # Set the name of the CloudFront function.
  name = each.value.name

  # Set the runtime environment for the CloudFront function (e.g., "cloudfront-js-1.0").
  runtime = each.value.runtime

  # Set a comment or description for the CloudFront function.
  comment = each.value.comment

  # Specify whether to publish the CloudFront function. 
  # If set to true, the function will be published, making it available for use in CloudFront distributions.
  publish = each.value.publish

  # Specify the code for the CloudFront function. The "file" function is used to read the content of the file specified in the "code" attribute.
  code = file(each.value.code)
}
