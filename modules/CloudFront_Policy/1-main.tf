# Define local variable for cache behaviors
locals {
  behaviors = {
    "NONE"      = "none"
    "WHITELIST" = "whitelist"
    "BLACKLIST" = "allExcept"
    "ALL"       = "all"
  }
}

# Create CloudFront cache policies based on input variables
resource "aws_cloudfront_cache_policy" "this" {
  # Iterate over the specified cache policies
  for_each = { for idx, policy in var.cloudfront_policies : idx => policy }

  # Cache policy name and optional comment
  name    = each.value.name
  comment = each.value.comment

  # Cache duration configuration
  default_ttl = each.value.default_ttl
  min_ttl     = each.value.min_ttl
  max_ttl     = each.value.max_ttl

  # Configure cache keys based on cookies, headers, and query strings
  parameters_in_cache_key_and_forwarded_to_origin {
    # Configure encoding formats for accepted content
    enable_accept_encoding_brotli = contains(each.value.supported_compression_formats, "BROTLI")
    enable_accept_encoding_gzip   = contains(each.value.supported_compression_formats, "GZIP")

    # Configure cache keys in cookies
    cookies_config {
      cookie_behavior = local.behaviors[each.value.cache_keys_in_cookies.behavior]

      # Dynamic block for cookies items
      dynamic "cookies" {
        for_each = contains(["WHITELIST", "BLACKLIST"], each.value.cache_keys_in_cookies.behavior) ? [each.value.cache_keys_in_cookies] : []

        content {
          items = cookies.value.items
        }
      }
    }

    # Configure cache keys in headers
    headers_config {
      header_behavior = local.behaviors[each.value.cache_keys_in_headers.behavior]

      # Dynamic block for headers items
      dynamic "headers" {
        for_each = contains(["WHITELIST"], each.value.cache_keys_in_headers.behavior) ? [each.value.cache_keys_in_headers] : []

        content {
          items = headers.value.items
        }
      }
    }

    # Configure cache keys in query strings
    query_strings_config {
      query_string_behavior = local.behaviors[each.value.cache_keys_in_query_strings.behavior]

      # Dynamic block for query strings items
      dynamic "query_strings" {
        for_each = contains(["WHITELIST", "BLACKLIST"], each.value.cache_keys_in_query_strings.behavior) ? [each.value.cache_keys_in_query_strings] : []

        content {
          items = query_strings.value.items
        }
      }
    }
  }
}
