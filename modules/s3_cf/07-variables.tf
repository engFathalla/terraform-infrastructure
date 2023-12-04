
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
variable "external_cloudfront_access_policy" {
  type = any
  default = {
    enable          = false
    distribution_id = ""
    account_id      = ""
  }
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

########################################
############# General settings #########
########################################


variable "enable_dr" {
  type    = bool
  default = false
}
variable "enable_cf" {
  type    = bool
  default = false
}
variable "s3_bucket_names" {
  type = list(string)
}
variable "project_name" {
  type = string
}
variable "prefix" {
  type    = string
  default = ""
}
variable "tags" {
  type        = map(any)
  description = "Map of Default Tags"
}
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
}
variable "server_side_encryption_configuration" {
  description = "Map containing server-side encryption configuration."
  type        = any
  default     = {}
}
variable "web_acl_id" {
  description = "If you're using AWS WAF to filter CloudFront requests, the Id of the AWS WAF web ACL that is associated with the distribution. The WAF Web ACL must exist in the WAF Global (CloudFront) region and the credentials configuring this argument must have waf:GetWebACL permissions assigned. If using WAFv2, provide the ARN of the web ACL."
  type        = string
  default     = null
}
variable "viewer_country_cache_policy_id" {
  type    = string
  default = null
}
##########################################
########## Lambda Function ###############
##########################################
variable "lambda_functions_associations" {
  description = "List of lambda function  for CloudFront cache behavior"
  type        = list(map(string))
  default     = []
}
##########################################
######## Function Associations ###########
##########################################
variable "function_associations" {
  description = "List of function associations for CloudFront cache behavior"
  type        = list(map(string))
  default     = []
}
# Additional Behaviors
variable "s3_buckets_with_cache_behavior" {
  type = list(object({
    bucket_name                 = string
    ordered_cache_behavior_path = string
    region = string
    # Add other cache behavior attributes as needed
  }))
  default = []
}
##########################################
######### Custom Error Response ##########
##########################################
variable "custom_error_response" {
  description = "List of custom error responses for CloudFront error pages"
  type        = list(map(string))
  default     = []
}
##########################################
############# Certificates ###############
##########################################
variable "viewer_certificate" {
  description = "The SSL configuration for this distribution"
  type        = any
  default = {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method = "sni-only"
  }
}