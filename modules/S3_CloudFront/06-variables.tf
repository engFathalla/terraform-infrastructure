# Project name variable
variable "project_name" {
  type        = string
  description = "The name of the project."
}

# Environment variable
variable "env" {
  type        = string
  description = "The environment for the project. Example: 'dev', 'prod', etc."
  default     = ""
}

# Default Tags variable
variable "tags" {
  type        = map(any)
  description = "A map of default tags to be applied to AWS resources."
  default     = {}
}

# Failover Region variable
variable "failover_region" {
  type        = string
  description = "The AWS region to be used for failover. Leave empty if failover is not configured."
  default     = ""
}

# S3 Bucket Configuration variable
variable "s3_bucket" {
  type = list(object({
    name = string
    logging_config = optional(list(object({
      include_cookies = bool
      prefix          = string
    })), [])
    prefix              = optional(string, "")
    default_root_object = optional(string, "index.html")
    enable_failover     = optional(bool, false)
    web_acl_id          = optional(string, null)
    http_version        = optional(string, "http3")
    wait_for_deployment = optional(bool, false)
    viewer_certificate = optional(any, {
      cloudfront_default_certificate = true
      minimum_protocol_version       = "TLSv1.2_2021"
      ssl_support_method             = "sni-only"
    })
    custom_error_response = optional(list(map(string)), [])
    default_cache_behavior = optional(any, {
    })

    ordered_s3_buckets_with_cache_behavior = optional(list(object({
      bucket_name                 = string
      path_pattern                = string
      region                      = string
      viewer_protocol_policy      = string
      allowed_methods             = list(string)
      cached_methods              = list(string)
      cache_policy_id             = string
      origin_request_policy_id    = string
      response_headers_policy_id  = string
      min_ttl                     = number
      default_ttl                 = number
      max_ttl                     = number
      function_association        = list(map(string))
      lambda_function_association = list(map(string))
    })), [])

    custom_origin_with_cache_behavior = optional(list(object({
      domain_name                 = string
      http_port                   = number
      https_port                  = number
      origin_protocol_policy      = string
      origin_ssl_protocols        = list(string)
      viewer_protocol_policy      = string
      allowed_methods             = list(string)
      cached_methods              = list(string)
      cache_policy_id             = string
      origin_request_policy_id    = string
      response_headers_policy_id  = string
      min_ttl                     = number
      default_ttl                 = number
      max_ttl                     = number
      function_association        = list(map(string))
      lambda_function_association = list(map(string))
    })), [])
  }))
  description = "Configuration for S3 buckets and associated CloudFront distributions."
}

# S3 Lifecycle Rules Configuration variable
variable "rules" {
  type = map(object({
    status = string
    noncurrent_version_expiration = optional(object({
      newer_noncurrent_versions = number # Number of noncurrent versions Amazon S3 will retain. Must be a non-zero positive integer.
      noncurrent_days           = number # Number of days an object is noncurrent before Amazon S3 can perform the associated action. Must be a positive integer
    }))
    noncurrent_version_transition = optional(object({
      newer_noncurrent_versions = number # Number of noncurrent versions Amazon S3 will retain. Must be a non-zero positive integer
      noncurrent_days           = number # Number of days an object is noncurrent before Amazon S3 can perform the associated action.
      storage_class             = string # Class of storage used to store the object. Valid Values: GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR
    }))
    abort_incomplete_multipart_upload = optional(object({
      days_after_initiation = number # Number of days after which Amazon S3 aborts an incomplete multipart upload.
    }))
  }))
  description = "Map containing S3 bucket lifecycle rules configuration."
}

# Server-Side Encryption Configuration variable
variable "server_side_encryption_configuration" {
  description = "Map containing server-side encryption configuration."
  type        = any
  default     = {}
}

######################################################
############## Failver Attached Policy ###############
######################################################
variable "failover_attach_policy" {
  description = "Controls if failover S3 bucket should have bucket policy attached (set to `true` to use value of `policy` as bucket policy)"
  type        = bool
  default     = false
}
variable "failover_policy" {
  description = "(Optional) A valid failover bucket policy JSON document. Note that if the policy document is not specific enough (but still valid), Terraform may view the policy as constantly changing in a terraform plan. In this case, please make sure you use the verbose/specific version of the policy. For more information about building AWS IAM policy documents with Terraform, see the AWS IAM Policy Document Guide."
  type        = string
  default     = null
}
########################################
########## Attach Policy ###############
########################################
variable "attach_policy" {
  description = "Controls if S3 bucket should have bucket policy attached (set to `true` to use value of `policy` as bucket policy)"
  type        = bool
  default     = false
}
variable "policy" {
  description = "(Optional) A valid bucket policy JSON document. Note that if the policy document is not specific enough (but still valid), Terraform may view the policy as constantly changing in a terraform plan. In this case, please make sure you use the verbose/specific version of the policy. For more information about building AWS IAM policy documents with Terraform, see the AWS IAM Policy Document Guide."
  type        = string
  default     = null
}
variable "attach_elb_log_delivery_policy" {
  description = "Controls if S3 bucket should have ELB log delivery policy attached"
  type        = bool
  default     = true
}

variable "attach_lb_log_delivery_policy" {
  description = "Controls if S3 bucket should have ALB/NLB log delivery policy attached"
  type        = bool
  default     = false
}

variable "attach_access_log_delivery_policy" {
  description = "Controls if S3 bucket should have S3 access log delivery policy attached"
  type        = bool
  default     = false
}

variable "attach_deny_insecure_transport_policy" {
  description = "Controls if S3 bucket should have deny non-SSL transport policy attached"
  type        = bool
  default     = true
}

variable "attach_require_latest_tls_policy" {
  description = "Controls if S3 bucket should require the latest version of TLS"
  type        = bool
  default     = false
}

variable "attach_public_policy" {
  description = "Controls if a user defined public bucket policy will be attached (set to `false` to allow upstream to apply defaults to the bucket)"
  type        = bool
  default     = true
}


variable "attach_deny_incorrect_encryption_headers" {
  description = "Controls if S3 bucket should deny incorrect encryption headers policy attached."
  type        = bool
  default     = false
}

variable "attach_deny_incorrect_kms_key_sse" {
  description = "Controls if S3 bucket policy should deny usage of incorrect KMS key SSE."
  type        = bool
  default     = false
}
variable "allowed_kms_key_arn" {
  description = "The ARN of KMS key which should be allowed in PutObject"
  type        = string
  default     = null
}

variable "attach_deny_unencrypted_object_uploads" {
  description = "Controls if S3 bucket should deny unencrypted object uploads policy attached."
  type        = bool
  default     = false
}
variable "access_log_delivery_policy_source_buckets" {
  description = "(Optional) List of S3 bucket ARNs wich should be allowed to deliver access logs to this bucket."
  type        = list(string)
  default     = []
}

variable "access_log_delivery_policy_source_accounts" {
  description = "(Optional) List of AWS Account IDs should be allowed to deliver access logs to this bucket."
  type        = list(string)
  default     = []
}