# Input variable for CloudFront cache policies
variable "cloudfront_policies" {
  type = list(object({
    # Name of the cache policy
    name = string

    # Optional comment for the cache policy
    comment = string

    # Cache duration configuration
    default_ttl = number
    min_ttl     = number
    max_ttl     = number

    # Set of supported compression formats
    supported_compression_formats = set(string)

    # Configuration for cache keys in cookies
    cache_keys_in_cookies = object({
      behavior = optional(string, "NONE")  # Behavior for cache keys in cookies (default: "NONE")
      items    = optional(set(string), []) # Set of cache keys in cookies (default: empty set)
    })

    # Configuration for cache keys in headers
    cache_keys_in_headers = object({
      behavior = optional(string, "NONE")  # Behavior for cache keys in headers (default: "NONE")
      items    = optional(set(string), []) # Set of cache keys in headers (default: empty set)
    })

    # Configuration for cache keys in query strings
    cache_keys_in_query_strings = object({
      behavior = optional(string, "NONE")  # Behavior for cache keys in query strings (default: "NONE")
      items    = optional(set(string), []) # Set of cache keys in query strings (default: empty set)
    })
  }))
}
