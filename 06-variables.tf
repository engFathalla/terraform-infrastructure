##########################################
############### General ##################
##########################################

# Project name for resource naming
variable "project_name" {
  type = string
}

# Environment identifier used in resource names
variable "env" {
  type = string
}

# Map of default tags
variable "tags" {
  type        = map(any)
  description = "Map of Default Tags"
}

# AWS region
variable "region" {
  type = string
}

##################################################
########## S3 Buckets And CloudFront  ############
##################################################

# Map of rules for S3 bucket lifecycle configuration
variable "rules" {
  type = map(object({
    status = string
    noncurrent_version_expiration = optional(object({
      newer_noncurrent_versions = number # Number of noncurrent versions Amazon S3 will retain.
      noncurrent_days           = number # Number of days an object is noncurrent before S3 can perform the associated action.
    }))
    noncurrent_version_transition = optional(object({
      newer_noncurrent_versions = number # Number of noncurrent versions Amazon S3 will retain.
      noncurrent_days           = number # Number of days an object is noncurrent before S3 can perform the associated action.
      storage_class             = string # Class of storage used to store the object.
    }))
    abort_incomplete_multipart_upload = optional(object({
      days_after_initiation = number # Number of days after which S3 aborts an incomplete multipart upload.
    }))
  }))
}

##################################################
##### CloudFront Functions   #####################
##################################################

# List of CloudFront functions
variable "cloudfront_functions" {
  type = list(object({
    name       = string
    runtime    = string
    comment    = string
    publish    = bool
    code       = string
    event_type = string
  }))

  default = [{
    name       = ""
    runtime    = ""
    comment    = ""
    publish    = false
    code       = ""
    event_type = ""
  }]
}

##################################################
############ CloudFront Policies #################
##################################################

# List of CloudFront cache policies
variable "cloudfront_policies" {
  type = list(object({
    name                          = string
    comment                       = string
    default_ttl                   = number
    min_ttl                       = number
    max_ttl                       = number
    supported_compression_formats = set(string)
    cache_keys_in_cookies = object({
      behavior = optional(string, "NONE")
      items    = optional(set(string), [])
    })
    cache_keys_in_headers = object({
      behavior = optional(string, "NONE")
      items    = optional(set(string), [])
    })
    cache_keys_in_query_strings = object({
      behavior = optional(string, "NONE")
      items    = optional(set(string), [])
    })
  }))
}

##########################################
############### Netwrok ##################
##########################################

# VPC CIDR block
variable "cidr_vpc" {
  type        = string
  description = "VPC CIDR block"
}

# Tags for Kubernetes private subnets
variable "tag_subnets_k8s_private" {
  type        = map(any)
  description = "Tags for Kubernetes private subnets"
}

# Tags for Kubernetes public subnets
variable "tag_subnets_k8s_public" {
  type        = map(any)
  description = "Tags for Kubernetes public subnets"
}

##########################################
################# EKS ####################
##########################################

# Amazon EKS cluster name
variable "cluster_name" {
  type = string
}

# Amazon EKS cluster version
variable "cluster_version" {
  type = string
}

# Map of configurations for managed node groups
variable "eks_managed_node_groups" {
  description = "Map of node group configurations"
  type        = map(any)
}

# List of AWS authentication roles for EKS
variable "aws_auth_roles" {
  description = "List of AWS auth roles"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
}
