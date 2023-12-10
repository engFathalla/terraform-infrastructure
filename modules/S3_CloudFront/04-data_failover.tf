# IAM policy document to combine multiple policies for failover buckets
data "aws_iam_policy_document" "failover_combined" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if buckets.enable_failover && local.attach_policy }

  # Combine policies based on conditions
  source_policy_documents = compact([
    var.attach_elb_log_delivery_policy ? data.aws_iam_policy_document.failover_elb_log_delivery[each.key].json : "",
    var.attach_lb_log_delivery_policy ? data.aws_iam_policy_document.failover_lb_log_delivery[each.key].json : "",
    var.attach_access_log_delivery_policy ? data.aws_iam_policy_document.failover_access_log_delivery[each.key].json : "",
    var.attach_require_latest_tls_policy ? data.aws_iam_policy_document.failover_require_latest_tls[each.key].json : "",
    var.attach_deny_insecure_transport_policy ? data.aws_iam_policy_document.failover_deny_insecure_transport[each.key].json : "",
    var.attach_deny_unencrypted_object_uploads ? data.aws_iam_policy_document.failover_deny_unencrypted_object_uploads[each.key].json : "",
    var.attach_deny_incorrect_kms_key_sse ? data.aws_iam_policy_document.failover_deny_incorrect_kms_key_sse[each.key].json : "",
    var.attach_deny_incorrect_encryption_headers ? data.aws_iam_policy_document.failover_deny_incorrect_encryption_headers[each.key].json : "",
    data.aws_iam_policy_document.failover_allow_cloudfront_access[each.key].json,
    var.failover_attach_policy ? var.failover_policy : ""
  ])
}

# Data source to get the current AWS region for failover
data "aws_region" "failover_current" {
  provider = aws.failover_region
}

# IAM policy document for ELB log delivery to failover buckets
data "aws_iam_policy_document" "failover_elb_log_delivery" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if buckets.enable_failover && var.attach_elb_log_delivery_policy }

  # Policy for AWS Regions created before August 2022 and after that
  dynamic "statement" {
    for_each = { for k, v in local.elb_service_accounts : k => v if k == data.aws_region.failover_current.name }

    content {
      sid = format("ELBRegion%s", title(statement.key))

      principals {
        type        = "AWS"
        identifiers = [format("arn:%s:iam::%s:root", data.aws_partition.current.partition, statement.value)]
      }

      effect = "Allow"

      actions = [
        "s3:PutObject",
      ]

      resources = [
        "${aws_s3_bucket.failover_buckets[each.key].arn}/*",
      ]
    }
  }

  statement {
    sid = ""

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.failover_buckets[each.key].arn}/*",
    ]
  }
}

# IAM policy document for LB log delivery to failover buckets
data "aws_iam_policy_document" "failover_lb_log_delivery" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if buckets.enable_failover && var.attach_lb_log_delivery_policy }

  statement {
    sid = "AWSLogDeliveryWrite"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.failover_buckets[each.key].arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid = "AWSLogDeliveryAclCheck"

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.failover_buckets[each.key].arn,
    ]
  }
}

# IAM policy document for S3 access log delivery to failover buckets
data "aws_iam_policy_document" "failover_access_log_delivery" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if buckets.enable_failover && var.attach_access_log_delivery_policy }

  statement {
    sid = "AWSAccessLogDeliveryWrite"

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.failover_buckets[each.key].arn}/*",
    ]

    dynamic "condition" {
      for_each = length(var.access_log_delivery_policy_source_buckets) != 0 ? [true] : []
      content {
        test     = "ForAnyValue:ArnLike"
        variable = "aws:SourceArn"
        values   = var.access_log_delivery_policy_source_buckets
      }
    }

    dynamic "condition" {
      for_each = length(var.access_log_delivery_policy_source_accounts) != 0 ? [true] : []
      content {
        test     = "ForAnyValue:StringEquals"
        variable = "aws:SourceAccount"
        values   = var.access_log_delivery_policy_source_accounts
      }
    }
  }

  statement {
    sid = "AWSAccessLogDeliveryAclCheck"

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
    ]

    resources = [
      aws_s3_bucket.failover_buckets[each.key].arn,
    ]
  }
}

# IAM policy document to deny insecure transport for failover buckets
data "aws_iam_policy_document" "failover_deny_insecure_transport" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if buckets.enable_failover && var.attach_deny_insecure_transport_policy }

  statement {
    sid    = "denyInsecureTransport"
    effect = "Deny"

    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.failover_buckets[each.key].arn,
      "${aws_s3_bucket.failover_buckets[each.key].arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
}

# IAM policy document to deny outdated TLS versions for failover buckets
data "aws_iam_policy_document" "failover_require_latest_tls" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if buckets.enable_failover && var.attach_require_latest_tls_policy }

  statement {
    sid    = "denyOutdatedTLS"
    effect = "Deny"

    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.failover_buckets[each.key].arn,
      "${aws_s3_bucket.failover_buckets[each.key].arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values = [
        "1.2"
      ]
    }
  }
}

# IAM policy document to deny incorrect encryption headers for failover buckets
data "aws_iam_policy_document" "failover_deny_incorrect_encryption_headers" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if buckets.enable_failover && var.attach_deny_incorrect_encryption_headers }

  statement {
    sid    = "denyIncorrectEncryptionHeaders"
    effect = "Deny"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.failover_buckets[each.key].arn}/*"
    ]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = try(var.server_side_encryption_configuration.rule.apply_server_side_encryption_by_default.sse_algorithm, null) == "aws:kms" ? ["aws:kms"] : ["AES256"]
    }
  }
}

# IAM policy document to deny incorrect KMS key SSE for failover buckets
data "aws_iam_policy_document" "failover_deny_incorrect_kms_key_sse" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if buckets.enable_failover && var.attach_deny_incorrect_kms_key_sse }

  statement {
    sid    = "denyIncorrectKmsKeySse"
    effect = "Deny"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.failover_buckets[each.key].arn}/*"
    ]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [try(var.allowed_kms_key_arn, null)]
    }
  }
}

# IAM policy document to deny unencrypted object uploads for failover buckets
data "aws_iam_policy_document" "failover_deny_unencrypted_object_uploads" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if buckets.enable_failover && var.attach_deny_unencrypted_object_uploads }

  statement {
    sid    = "denyUnencryptedObjectUploads"
    effect = "Deny"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.failover_buckets[each.key].arn}/*"
    ]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = [true]
    }
  }
}

# IAM policy document to allow CloudFront access for failover buckets
data "aws_iam_policy_document" "failover_allow_cloudfront_access" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if buckets.enable_failover }
  statement {
    sid    = "allowCloudfrontAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.failover_buckets[each.key].arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["${aws_cloudfront_distribution.s3_distribution[each.key].arn}"]
    }
  }
}
