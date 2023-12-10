# Generate a random string to be used in CloudFront origin group ID
resource "random_string" "random" {
  length  = 4     # Length of the generated password
  special = false # Include special characters in the generated password
}

# CloudFront Origin Access Control (OAC) to control access to S3 bucket origins
resource "aws_cloudfront_origin_access_control" "oac" {
  for_each                          = { for idx, buckets in var.s3_bucket : idx => buckets }
  name                              = each.value.prefix != "" ? "${each.value.prefix}_${each.value.name}_oac_role" : "${each.value.name}_oac_role"
  description                       = "OAC to access ${each.value.name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution to distribute content globally with S3 bucket as origin
resource "aws_cloudfront_distribution" "s3_distribution" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets }

  # The main Origin
  origin {
    domain_name              = aws_s3_bucket.multiple_buckets[each.key].bucket_regional_domain_name
    origin_id                = aws_s3_bucket.multiple_buckets[each.key].bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac[each.key].id
  }

  # Failover Origin
  dynamic "origin" {
    for_each = can(aws_s3_bucket.failover_buckets[each.key]) ? [aws_s3_bucket.failover_buckets[each.key]] : []
    content {
      domain_name              = origin.value["bucket_regional_domain_name"]
      origin_id                = origin.value["bucket_regional_domain_name"]
      origin_access_control_id = aws_cloudfront_origin_access_control.oac[each.key].id
    }
  }

  # Custom Origin Domain
  dynamic "origin" {
    for_each = each.value.custom_origin_with_cache_behavior
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.value.domain_name
      dynamic "custom_origin_config" {
        for_each = each.value.custom_origin_with_cache_behavior
        content {
          http_port              = custom_origin_config.value.http_port
          https_port             = custom_origin_config.value.https_port
          origin_protocol_policy = custom_origin_config.value.origin_protocol_policy
          origin_ssl_protocols   = custom_origin_config.value.origin_ssl_protocols
        }
      }
    }
  }

  # Additional S3 Origins
  dynamic "origin" {
    for_each = each.value.ordered_s3_buckets_with_cache_behavior
    content {
      domain_name              = "${origin.value.bucket_name}.s3.${data.aws_region.current.name}.amazonaws.com"
      origin_id                = "${origin.value.bucket_name}.s3.${data.aws_region.current.name}.amazonaws.com"
      origin_access_control_id = aws_cloudfront_origin_access_control.oac[each.key].id
    }
  }

  # Origin Group for failover
  dynamic "origin_group" {
    for_each = can(aws_s3_bucket.failover_buckets[each.key]) ? [aws_s3_bucket.failover_buckets[each.key]] : []
    content {
      origin_id = "${aws_s3_bucket.multiple_buckets[each.key].bucket_regional_domain_name}-${random_string.random.result}"
      failover_criteria {
        status_codes = [403, 404, 500, 502]
      }
      member {
        origin_id = aws_s3_bucket.multiple_buckets[each.key].bucket_regional_domain_name
      }
      member {
        origin_id = origin_group.value["bucket_regional_domain_name"]
      }
    }
  }

  wait_for_deployment = lookup(each.value, "wait_for_deployment", "false")
  http_version        = lookup(each.value, "http_version", "http3")
  aliases             = lookup(each.value.viewer_certificate, "aliases", null)
  enabled             = true
  is_ipv6_enabled     = true
  web_acl_id          = lookup(each.value, "web_acl_id", null)
  comment             = aws_s3_bucket.multiple_buckets[each.key].bucket
  price_class         = "PriceClass_100"
  default_root_object = "index.html"

  # Default Cache Behavior
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.multiple_buckets[each.key].bucket_regional_domain_name
    compress         = true

    # Forwarded values configuration
    dynamic "forwarded_values" {
      for_each = can(tostring(each.value.default_cache_behavior.cache_policy_id)) || can(each.value.default_cache_behavior.origin_request_policy_id) || can(each.value.default_cache_behavior.response_headers_policy_id) ? [] : [1]
      content {
        query_string = true
        cookies {
          forward = "all"
        }
      }
    }

    # Cache policy, origin request policy, and response headers policy configuration
    cache_policy_id            = lookup(each.value.default_cache_behavior, "cache_policy_id", null)
    origin_request_policy_id   = lookup(each.value.default_cache_behavior, "origin_request_policy_id", null)
    response_headers_policy_id = lookup(each.value.default_cache_behavior, "response_headers_policy_id", null)

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = can(each.value.default_cache_behavior.min_ttl) ? each.value.default_cache_behavior.min_ttl : null
    default_ttl            = can(each.value.default_cache_behavior.default_ttl) ? each.value.default_cache_behavior.default_ttl : null
    max_ttl                = can(each.value.default_cache_behavior.max_ttl) ? each.value.default_cache_behavior.max_ttl : null

    # Lambda function association configuration
    dynamic "lambda_function_association" {
      for_each = can(each.value.default_cache_behavior.lambda_function_association) ? each.value.default_cache_behavior.lambda_function_association : []
      content {
        lambda_arn   = lambda_function_association.value["lambda_arn"]
        event_type   = lambda_function_association.value["event_type"]
        include_body = lambda_function_association.value["include_body"]
      }
    }

    # Function association configuration
    dynamic "function_association" {
      for_each = each.value.default_cache_behavior.function_associations
      content {
        function_arn = function_association.value["function_arn"]
        event_type   = function_association.value["event_type"]
      }
    }
  }

  # Cache behavior with For S3 Buckets
  dynamic "ordered_cache_behavior" {
    for_each = each.value.ordered_s3_buckets_with_cache_behavior

    content {
      path_pattern     = ordered_cache_behavior.value["path_pattern"]
      allowed_methods  = ordered_cache_behavior.value["allowed_methods"]
      cached_methods   = ordered_cache_behavior.value["cached_methods"]
      target_origin_id = "${ordered_cache_behavior.value["bucket_name"]}.s3.${data.aws_region.current.name}.amazonaws.com"
      compress         = true

      # Forwarded values configuration
      dynamic "forwarded_values" {
        for_each = can(tostring(ordered_cache_behavior.value["cache_policy_id"])) || can(ordered_cache_behavior.value["origin_request_policy_id"]) || can(ordered_cache_behavior.value["response_headers_policy_id"]) ? [] : [1]
        content {
          query_string = true
          cookies {
            forward = "all"
          }
        }
      }

      # Cache policy, origin request policy, and response headers policy configuration
      cache_policy_id            = ordered_cache_behavior.value["cache_policy_id"]
      origin_request_policy_id   = ordered_cache_behavior.value["origin_request_policy_id"]
      response_headers_policy_id = ordered_cache_behavior.value["response_headers_policy_id"]
      viewer_protocol_policy     = ordered_cache_behavior.value["viewer_protocol_policy"]
      min_ttl                    = ordered_cache_behavior.value["min_ttl"]
      default_ttl                = ordered_cache_behavior.value["default_ttl"]
      max_ttl                    = ordered_cache_behavior.value["max_ttl"]

      # Function association configuration
      dynamic "function_association" {
        for_each = ordered_cache_behavior.value.function_association
        content {
          function_arn = function_association.value["function_arn"]
          event_type   = function_association.value["event_type"]
        }
      }

      # Lambda function association configuration
      dynamic "lambda_function_association" {
        for_each = ordered_cache_behavior.value.lambda_function_association
        content {
          lambda_arn   = lambda_function_association.value["lambda_arn"]
          event_type   = lambda_function_association.value["event_type"]
          include_body = lambda_function_association.value["include_body"]
        }
      }
    }
  }

  # Cache behavior with For Custom Origin Domain
  dynamic "ordered_cache_behavior" {
    for_each = each.value.custom_origin_with_cache_behavior

    content {
      path_pattern     = ordered_cache_behavior.value["path_pattern"]
      allowed_methods  = ordered_cache_behavior.value["allowed_methods"]
      cached_methods   = ordered_cache_behavior.value["cached_methods"]
      target_origin_id = ordered_cache_behavior.value["domain_name"]
      compress         = true

      # Forwarded values configuration
      dynamic "forwarded_values" {
        for_each = can(tostring(ordered_cache_behavior.value["cache_policy_id"])) || can(ordered_cache_behavior.value["origin_request_policy_id"]) || can(ordered_cache_behavior.value["response_headers_policy_id"]) ? [] : [1]
        content {
          query_string = true
          cookies {
            forward = "all"
          }
        }
      }

      # Cache policy, origin request policy, and response headers policy configuration
      cache_policy_id            = ordered_cache_behavior.value["cache_policy_id"]
      origin_request_policy_id   = ordered_cache_behavior.value["origin_request_policy_id"]
      response_headers_policy_id = ordered_cache_behavior.value["response_headers_policy_id"]
      viewer_protocol_policy     = ordered_cache_behavior.value["viewer_protocol_policy"]
      min_ttl                    = ordered_cache_behavior.value["min_ttl"]
      default_ttl                = ordered_cache_behavior.value["default_ttl"]
      max_ttl                    = ordered_cache_behavior.value["max_ttl"]

      # Function association configuration
      dynamic "function_association" {
        for_each = ordered_cache_behavior.value.function_association
        content {
          function_arn = function_association.value["function_arn"]
          event_type   = function_association.value["event_type"]
        }
      }

      # Lambda function association configuration
      dynamic "lambda_function_association" {
        for_each = ordered_cache_behavior.value.lambda_function_association
        content {
          lambda_arn   = lambda_function_association.value["lambda_arn"]
          event_type   = lambda_function_association.value["event_type"]
          include_body = lambda_function_association.value["include_body"]
        }
      }
    }
  }

  # Custom error responses
  dynamic "custom_error_response" {
    for_each = each.value.custom_error_response
    content {
      error_caching_min_ttl = custom_error_response.value["error_caching_min_ttl"]
      error_code            = custom_error_response.value["error_code"]
      response_code         = custom_error_response.value["response_code"]
      response_page_path    = custom_error_response.value["response_page_path"]
    }
  }

  # Restrictions configuration
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Logging configuration
  dynamic "logging_config" {
    for_each = each.value.logging_config
    content {
      include_cookies = logging_config.value["include_cookies"]
      bucket          = aws_s3_bucket.multiple_buckets[each.key].bucket_regional_domain_name
      prefix          = logging_config.value["prefix"]
    }
  }

  # Viewer certificate configuration
  viewer_certificate {
    acm_certificate_arn            = lookup(each.value.viewer_certificate, "acm_certificate_arn", null)
    cloudfront_default_certificate = lookup(each.value.viewer_certificate, "cloudfront_default_certificate", null)
    iam_certificate_id             = lookup(each.value.viewer_certificate, "iam_certificate_id", null)
    minimum_protocol_version       = lookup(each.value.viewer_certificate, "minimum_protocol_version", "TLSv1")
    ssl_support_method             = lookup(each.value.viewer_certificate, "ssl_support_method", null)
  }

  # Tags for the CloudFront distribution
  tags = var.tags

  # Dependencies on other resources
  depends_on = [aws_s3_bucket_ownership_controls.this]
}
