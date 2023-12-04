# Retrieve the AWS account identity information for the current authenticated caller
data "aws_caller_identity" "current" {}

# Retrieve information about the availability zones in the current AWS region
data "aws_availability_zones" "available" {}

# Retrieve information about the current AWS region
data "aws_region" "current" {}
