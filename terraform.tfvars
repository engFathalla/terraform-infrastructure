##########################################
############### General ##################
##########################################

# Project name for resource naming
project_name = "demo-project"

# Environment identifier used in resource names
env = "prod"

# AWS region
region = "eu-west-1"

# Map of default tags
tags = {
  Project     = "demo-project"
  Environment = "PROD"
}

##################################################
########## S3 Buckets And CloudFront  ############
##################################################
# Map of rules for S3 bucket lifecycle configuration
rules = {
  "keep-latest-version" = {
    status = "Enabled"

    noncurrent_version_expiration = {
      newer_noncurrent_versions = 13
      noncurrent_days           = 31
    }
    noncurrent_version_transition = {
      newer_noncurrent_versions = 1
      noncurrent_days           = 30
      storage_class             = "STANDARD_IA"
    }
    abort_incomplete_multipart_upload = {
      days_after_initiation = 1
    }
  }
}

##################################################
##### CloudFront Functions   #####################
##################################################

# List of CloudFront functions
cloudfront_functions = [
  {
    name       = "url-rewrite"
    runtime    = "cloudfront-js-1.0"
    comment    = "url-rewrite"
    publish    = true
    code       = "CloudFront_Functions/url-rewrite.js"
    event_type = "viewer-request"
  }
]
##################################################
############ CloudFront Policies #################
##################################################

# List of CloudFront cache policies
cloudfront_policies = [
  {
    name                          = "cache_policy"
    comment                       = "cache_policy"
    default_ttl                   = 30672000
    min_ttl                       = 0
    max_ttl                       = 30672000
    supported_compression_formats = ["BROTLI", "GZIP"]
    cache_keys_in_cookies = { behavior = "ALL" }
    cache_keys_in_headers = { behavior = "WHITELIST", items = ["cloudfront-viewer-country"] }
    cache_keys_in_query_strings = { behavior = "ALL" }
  }
]

##########################################
############### Network ##################
##########################################

# VPC CIDR block
cidr_vpc = "10.32.0.0/16"

# Tags for Kubernetes private subnets
tag_subnets_k8s_private = {
  Project                           = "demo-project"
  Environment                       = "PROD"
  "kubernetes.io/role/internal-elb" = "1"
}

# Tags for Kubernetes public subnets
tag_subnets_k8s_public = {
  Project                  = "demo-project"
  Environment              = "PROD"
  "kubernetes.io/role/elb" = "1"
}

##########################################
################# EKS ####################
##########################################

# Amazon EKS cluster name
cluster_name = "demo-project"

# Amazon EKS cluster version
cluster_version = "1.27"

# Map of configurations for managed node groups
eks_managed_node_groups = {
  "demo-project" = {
    desired_size               = 1
    min_size                   = 1
    max_size                   = 10
    use_custom_launch_template = true
    enable_bootstrap_user_data = true
    labels = { role = "demo-project" }
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 60
          volume_type           = "gp2"
          iops                  = 0
          encrypted             = true
          delete_on_termination = true
        }
      }
    }
    taints = {}
    tags = { Project = "demo-project", Environment = "PROD" }
  }
}
# List of AWS authentication roles for EKS
aws_auth_roles = [
  {
    rolearn  = "arn:aws:iam::<Account-ID>:role/Administrator"
    username = "eks-web-console"
    groups   = ["dc:cluster:admin"]
  }
]
