resource "random_string" "random" {
  length           = 4                                    # Length of the generated password
  special          = false                                  # Include special characters in the generated password
}
resource "aws_cloudfront_origin_access_control" "oac" {
  count                             = var.enable_cf ? 1 : 0
  name                              = var.prefix == "" ? "${var.project_name}_oac_role" : "${var.project_name}_${var.prefix}_oac_role"
  description                       = ""
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

########################################################################
resource "aws_cloudfront_distribution" "s3_distribution" {
  count = var.enable_cf ? length(var.s3_bucket_names) : 0
  origin {
    domain_name              = aws_s3_bucket.multiple_buckets[count.index].bucket_regional_domain_name
    origin_id                = aws_s3_bucket.multiple_buckets[count.index].bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac[0].id
  }
  dynamic "origin" {
    for_each = var.s3_buckets_with_cache_behavior
    
    content {
      domain_name              = "${origin.value.bucket_name}.s3.${data.aws_region.current.name}.amazonaws.com"
      origin_id                = "${origin.value.bucket_name}.s3.${data.aws_region.current.name}.amazonaws.com"
      origin_access_control_id = aws_cloudfront_origin_access_control.oac[0].id
    }
  }
  dynamic "origin" {
    for_each = var.enable_dr ? [for idx, bucket in aws_s3_bucket.dr_multiple_buckets : bucket if idx == count.index] : []

    content {
      domain_name              = aws_s3_bucket.dr_multiple_buckets[count.index].bucket_regional_domain_name
      origin_id                = aws_s3_bucket.dr_multiple_buckets[count.index].bucket_regional_domain_name
      origin_access_control_id = aws_cloudfront_origin_access_control.oac[0].id
    }
  }
  dynamic "origin_group" {
    for_each = var.enable_dr ? [1] : []
    content {
      origin_id = "${aws_s3_bucket.multiple_buckets[count.index].bucket_regional_domain_name}-${random_string.random.result}"
      failover_criteria {
        status_codes = [403, 404, 500, 502]
      }
      member {
        origin_id = aws_s3_bucket.multiple_buckets[count.index].bucket_regional_domain_name
      }
      member {
        origin_id = aws_s3_bucket.dr_multiple_buckets[count.index].bucket_regional_domain_name
      }
    }
  }
  aliases = lookup(var.viewer_certificate, "aliases", null)
  
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http3"
  web_acl_id          = var.web_acl_id 
  comment             = aws_s3_bucket.multiple_buckets[count.index].bucket
  price_class         = "PriceClass_100"
  default_root_object = "index.html"
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = var.enable_dr ? "${aws_s3_bucket.multiple_buckets[count.index].bucket_regional_domain_name}-${random_string.random.result}" : aws_s3_bucket.multiple_buckets[count.index].bucket_regional_domain_name
    compress         = true
    dynamic "forwarded_values" {
      for_each = var.viewer_country_cache_policy_id == "" ? [] : [1]
      content {
        query_string = true
        cookies {
          forward = "all"
        }
      }
    }
    cache_policy_id        = var.viewer_country_cache_policy_id
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.viewer_country_cache_policy_id == "" ? null : 0
    default_ttl            = var.viewer_country_cache_policy_id == "" ? null : 3600
    max_ttl                = var.viewer_country_cache_policy_id == "" ? null : 86400

    dynamic "lambda_function_association" {
      for_each = var.lambda_functions_associations
      content {
        lambda_arn   = lambda_function_association.value["lambda_arn"]
        event_type   = lambda_function_association.value["event_type"]
        include_body = lambda_function_association.value["include_body"]
      }
    }
    dynamic "function_association" {
      for_each = var.function_associations
      content {
        function_arn = function_association.value["function_arn"]
        event_type   = function_association.value["event_type"]
      }
    }
  }
  # Additional Behaviors
  dynamic "ordered_cache_behavior" {
    for_each = var.s3_buckets_with_cache_behavior

    content {
      path_pattern     = ordered_cache_behavior.value.ordered_cache_behavior_path
      allowed_methods  = ["GET", "HEAD", "OPTIONS"]
      cached_methods   = ["GET", "HEAD", "OPTIONS"]
      target_origin_id = "${ordered_cache_behavior.value.bucket_name}.s3.${data.aws_region.current.name}.amazonaws.com"
      compress         = true

      dynamic "forwarded_values" {
        for_each = var.viewer_country_cache_policy_id == "" ? [] : [1]

        content {
          query_string = true

          cookies {
            forward = "all"
          }
        }
      }

      cache_policy_id        = var.viewer_country_cache_policy_id
      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = var.viewer_country_cache_policy_id == "" ? null : 0
      default_ttl            = var.viewer_country_cache_policy_id == "" ? null : 3600
      max_ttl                = var.viewer_country_cache_policy_id == "" ? null : 86400

    dynamic "lambda_function_association" {
      for_each = var.lambda_functions_associations
      content {
        lambda_arn   = lambda_function_association.value["lambda_arn"]
        event_type   = lambda_function_association.value["event_type"]
        include_body = lambda_function_association.value["include_body"]
      }
    }
    dynamic "function_association" {
      for_each = var.function_associations
      content {
        function_arn = function_association.value["function_arn"]
        event_type   = function_association.value["event_type"]
      }
    }
    }
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_response
    content {
      error_caching_min_ttl = custom_error_response.value["error_caching_min_ttl"]
      error_code            = custom_error_response.value["error_code"]
      response_code         = custom_error_response.value["response_code"]
      response_page_path    = custom_error_response.value["response_page_path"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = lookup(var.viewer_certificate, "acm_certificate_arn", null)
    cloudfront_default_certificate = lookup(var.viewer_certificate, "cloudfront_default_certificate", null)
    iam_certificate_id             = lookup(var.viewer_certificate, "iam_certificate_id", null)

    minimum_protocol_version = lookup(var.viewer_certificate, "minimum_protocol_version", "TLSv1")
    ssl_support_method       = lookup(var.viewer_certificate, "ssl_support_method", null)
  }
  tags = var.tags
}
