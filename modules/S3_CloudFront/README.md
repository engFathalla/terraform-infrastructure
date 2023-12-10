# Terraform AWS S3 and CloudFront Module 🔥

## Description

This Terraform module deploys an S3 bucket with optional features and a CloudFront distribution with configurable settings on AWS.

## ✨Input Variables


| Variable                              | Type          | Required/Optional   | Description |
| ------------------------------------- | ------------- | ------------------- | ----------- |
| `project_name`                        | `string`      | **Required**        | The name of the project. |
| `env`                                 | `string`      | Optional            | The environment for the project. Example: 'dev', 'prod', etc. |
| `tags`                                | `map(any)`    | Optional            | Map of default tags to be applied to AWS resources. |
| `failover_region`                     | `string`      | Optional            | The AWS region to be used for failover. Leave empty if failover is not configured. |
| `s3_bucket`                           | `list(object)`| **Required**        | Configuration for S3 buckets and associated CloudFront distributions. |
| &nbsp;&nbsp;&nbsp;&nbsp; `name`               | `string`      | **Required**        | The name of the S3 bucket. |
| &nbsp;&nbsp;&nbsp;&nbsp; `logging_config`     | `list(object)`| Optional            | Logging configuration for the S3 bucket. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; `include_cookies`| `bool`        | Optional            | Include cookies in the logs. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; `prefix`         | `string`      | Optional            | Prefix for the logs. |
| &nbsp;&nbsp;&nbsp;&nbsp; `prefix`             | `string`      | Optional            | Prefix for the S3 bucket. |
| &nbsp;&nbsp;&nbsp;&nbsp; `default_root_object`| `string`      | Optional            | Default root object for the S3 bucket. |
| &nbsp;&nbsp;&nbsp;&nbsp; `enable_failover`    | `bool`        | Optional            | Enable failover for the S3 bucket. |
| &nbsp;&nbsp;&nbsp;&nbsp; `web_acl_id`         | `string`      | Optional            | Web ACL ID for the S3 bucket. |
| &nbsp;&nbsp;&nbsp;&nbsp; `http_version`       | `string`      | Optional            | HTTP version for the S3 bucket. |
| &nbsp;&nbsp;&nbsp;&nbsp; `wait_for_deployment`| `bool`        | Optional            | Wait for deployment for the S3 bucket. |
| &nbsp;&nbsp;&nbsp;&nbsp; `viewer_certificate`| `any`         | Optional            | Viewer certificate configuration for the S3 bucket. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; `cloudfront_default_certificate`| `bool`        | Optional            | Use CloudFront default certificate. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; `minimum_protocol_version`      | `string`      | Optional            | Minimum protocol version. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; `ssl_support_method`           | `string`      | Optional            | SSL support method. |
| &nbsp;&nbsp;&nbsp;&nbsp; `custom_error_response`| `list(map(string))`| Optional      | Custom error response configuration for the S3 bucket. |
| &nbsp;&nbsp;&nbsp;&nbsp; `default_cache_behavior`| `any`       | Optional            | Default cache behavior configuration for the S3 bucket. |
| &nbsp;&nbsp;&nbsp;&nbsp; `ordered_s3_buckets_with_cache_behavior`| `list(object)`| Optional | Configuration for ordered S3 buckets with cache behavior. |
| &nbsp;&nbsp;&nbsp;&nbsp; `custom_origin_with_cache_behavior`   | `list(object)`| Optional | Configuration for custom origin with cache behavior. |
| `rules`                               | `map(object)` | Optional            | Map containing S3 bucket lifecycle rules configuration. |
| `server_side_encryption_configuration`| `any`         | Optional            | Map containing server-side encryption configuration. |
| `failover_attach_policy`               | `bool`        | Optional            | Controls if failover S3 bucket should have bucket policy attached (set to `true` to use value of `policy` as bucket policy). |
| `failover_policy`                      | `string`      | Optional            | A valid failover bucket policy JSON document. Note that if the policy document is not specific enough (but still valid), Terraform may view the policy as constantly changing in a terraform plan. In this case, please make sure you use the verbose/specific version of the policy. For more information about building AWS IAM policy documents with Terraform, see the AWS IAM Policy Document Guide. |
| `attach_policy`                       | `bool`        | Optional            | Controls if S3 bucket should have bucket policy attached (set to `true` to use value of `policy` as bucket policy). |
| `policy`                              | `string`      | Optional            | A valid bucket policy JSON document. Note that if the policy document is not specific enough (but still valid), Terraform may view the policy as constantly changing in a terraform plan. In this case, please make sure you use the verbose/specific version of the policy. For more information about building AWS IAM policy documents with Terraform, see the AWS IAM Policy Document Guide. |
| `attach_elb_log_delivery_policy`       | `bool`        | Optional            | Controls if S3 bucket should have ELB log delivery policy attached. |
| `attach_lb_log_delivery_policy`       | `bool`        | Optional            | Controls if S3 bucket should have ALB/NLB log delivery policy attached. |
| `attach_access_log_delivery_policy`   | `bool`        | Optional            | Controls if S3 bucket should have S3 access log delivery policy attached. |
| `attach_deny_insecure_transport_policy`| `bool`        | Optional            | Controls if S3 bucket should have deny non-SSL transport policy attached. |
| `attach_require_latest_tls_policy`    | `bool`        | Optional            | Controls if S3 bucket should require the latest version of TLS. |
| `attach_public_policy`                 | `bool`        | Optional            | Controls if a user defined public bucket policy will be attached (set to `false` to allow upstream to apply defaults to the bucket). |
| `attach_deny_incorrect_encryption_headers`| `bool`    | Optional            | Controls if S3 bucket should deny incorrect encryption headers policy attached. |
| `attach_deny_incorrect_kms_key_sse`   | `bool`        | Optional            | Controls if S3 bucket policy should deny usage of incorrect KMS key SSE. |
| `allowed_kms_key_arn`                 | `string`      | Optional            | The ARN of KMS key which should be allowed in PutObject. |
| `attach_deny_unencrypted_object_uploads`| `bool`     | Optional            | Controls if S3 bucket should deny unencrypted object uploads policy attached. |
| `access_log_delivery_policy_source_buckets`| `list(string)` | Optional         | List of S3 bucket ARNs which should be allowed to deliver access logs to this bucket. |
| `access_log_delivery_policy_source_accounts`| `list(string)`| Optional        | List of AWS Account IDs should be allowed to deliver access logs to this bucket. |


## ✨Outputs

| Output               | Description                                              |
| -------------------- | -------------------------------------------------------- |
| `multiple_buckets`   | Output block for multiple S3 buckets.                    |
| `s3_distribution`    | Output block for CloudFront distribution associated with S3 buckets. |

## Usage

```hcl
module "s3_cloudfront" {
  source = "your-source"
  # Input variables
  project_name      = "your-project-name"
  env               = "your-environment"
  tags              = { "key" = "value" }
  s3_bucket = [
    {
      name = "project-demo-1" # type String
      default_cache_behavior = {
        cache_policy_id = module.cloudfront_policies.id[0] # type String
        function_associations = [
          {
            function_arn = module.cloudfront_functions.function_arns[0] # type String
            event_type   = module.cloudfront_functions.function_event_types[0] # type String
          },
          {
            function_arn = module.cloudfront_functions.function_arns[1] # type String
            event_type   = module.cloudfront_functions.function_event_types[1] # type String
          },
          # Add other function associations if needed
        ]
      }
      viewer_certificate = {
        acm_certificate_arn      = "arn:aws:acm:us-east-1:**:certificate/***" # type String
        minimum_protocol_version = "TLSv1.2_2021"
        ssl_support_method       = "sni-only"
        aliases                  = ["auth.my-domain.xyz"] # type list(String)
      }

    },
    {
      name = "project-demo-1" # type String
      default_cache_behavior = {
        cache_policy_id = module.cloudfront_policies.id[0] # type String
        function_associations = [
          {
            function_arn = module.cloudfront_functions.function_arns[0] # type String
            event_type   = module.cloudfront_functions.function_event_types[0] # type String
          },
          {
            function_arn = module.cloudfront_functions.function_arns[1] # type String
            event_type   = module.cloudfront_functions.function_event_types[1] # type String
          },
          # Add other function associations if needed
        ]
      }
      viewer_certificate = {
        acm_certificate_arn      = "arn:aws:acm:us-east-1:**:certificate/***" # type String
        minimum_protocol_version = "TLSv1.2_2021"
        ssl_support_method       = "sni-only"
        aliases                  = ["auth.my-domain.xyz"] # type list(String)
      }

    },
   ### Add other Buckets if needed
  ]
}
```


