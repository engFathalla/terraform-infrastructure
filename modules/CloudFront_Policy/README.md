# Terraform AWS CloudFront Cache Policies 🔥

This Terraform module creates CloudFront cache policies with flexible configurations to control caching behavior.

## Table of Contents

- [Introduction](#introduction)
- [Usage](#usage)
- [Inputs](#inputs)
- [Outputs](#outputs)

## Introduction

This Terraform module provides a flexible way to manage AWS CloudFront cache policies. CloudFront cache policies define how CloudFront handles content caching, allowing you to fine-tune caching behavior for your web distributions.

## Usage

```hcl
module "cloudfront_policies" {
  source = "./path/to/cloudfront_policies"

  cloudfront_policies = [
    {
      name                          = "example-policy"
      comment                       = "An example cache policy"
      default_ttl                   = 3600
      min_ttl                       = 60
      max_ttl                       = 86400
      supported_compression_formats = ["GZIP", "BROTLI"]

      cache_keys_in_cookies = {
        behavior = "WHITELIST"
        items    = ["user_id", "session_id"]
      }

      cache_keys_in_headers = {
        behavior = "NONE"
      }

      cache_keys_in_query_strings = {
        behavior = "ALL"
      }
    },
    # Add more policies if needed
  ]
}

# Output example
output "cache_policy_etags" {
  value = module.cloudfront_policies.etag
}

output "cache_policy_ids" {
  value = module.cloudfront_policies.id
}

```
## Inputs

### Variable `cloudfront_policies`

| Name                                  | Type          | Required/Optional | Description                                                      |
| ------------------------------------- | ------------- | ------------------ | ----------------------------------------------------------------- |
| `name`                                | string        | Required           | The name of the cache policy.                                     |
| `comment`                             | string        | Required           | A comment describing the cache policy.                            |
| `default_ttl`                         | number        | Required           | Default time-to-live (TTL) for objects in the cache.              |
| `min_ttl`                             | number        | Required           | Minimum TTL for objects in the cache.                             |
| `max_ttl`                             | number        | Required           | Maximum TTL for objects in the cache.                             |
| `supported_compression_formats`       | set(string)   | Required           | Set of compression formats supported.                             |
| `cache_keys_in_cookies`               | object        | Optional           | Configuration for caching based on cookies. See below for details.|
| `cache_keys_in_headers`               | object        | Optional           | Configuration for caching based on headers. See below for details.|
| `cache_keys_in_query_strings`         | object        | Optional           | Configuration for caching based on query strings. See below for details.|

#### Configuration for `cache_keys_in_cookies`

| Name          | Type          | Required/Optional | Description                                           |
| ------------- | ------------- | ------------------ | ----------------------------------------------------- |
| `behavior`    | string        | Optional (default: "NONE") | Cache behavior for cookies. Possible values: "NONE", "WHITELIST", "BLACKLIST", "ALL". |
| `items`       | set(string)   | Optional           | Set of cookie names to include or exclude based on the behavior. |

#### Configuration for `cache_keys_in_headers`

| Name          | Type          | Required/Optional | Description                                           |
| ------------- | ------------- | ------------------ | ----------------------------------------------------- |
| `behavior`    | string        | Optional (default: "NONE") | Cache behavior for headers. Possible values: "NONE", "WHITELIST", "ALL". |
| `items`       | set(string)   | Optional           | Set of header names to include based on the behavior. |

#### Configuration for `cache_keys_in_query_strings`

| Name          | Type          | Required/Optional | Description                                           |
| ------------- | ------------- | ------------------ | ----------------------------------------------------- |
| `behavior`    | string        | Optional (default: "NONE") | Cache behavior for query strings. Possible values: "NONE", "WHITELIST", "BLACKLIST", "ALL". |
| `items`       | set(string)   | Optional           | Set of query string names to include or exclude based on the behavior. |


### Output

| Name          | Type   | Description                            |
| ------------- | ------ | -------------------------------------- |
| `etag`        | list   | List of ETags for each cache policy.    |
| `id`          | list   | List of IDs for each cache policy.      |

