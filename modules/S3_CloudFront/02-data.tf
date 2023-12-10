###################### Data Sources #####################

# Retrieve the current AWS region, caller identity, and partition information
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# Define local variable for Elastic Load Balancer (ELB) service accounts in different AWS regions
locals {
  elb_service_accounts = {
    us-east-1 = "127311923021"
    us-east-2 = "033677994240"
    # ... (other regions)
  }
}

# IAM Policy Document for ELB Log Delivery
data "aws_iam_policy_document" "elb_log_delivery" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if var.attach_elb_log_delivery_policy }

  # Define statements for different regions
  dynamic "statement" {
    for_each = { for k, v in local.elb_service_accounts : k => v if k == data.aws_region.current.name }

    content {
      sid = format("ELBRegion%s", title(statement.key))

      # Define permissions for ELB service accounts in the specified region
      principals {
        type        = "AWS"
        identifiers = [format("arn:%s:iam::%s:root", data.aws_partition.current.partition, statement.value)]
      }

      effect = "Allow"

      actions = [
        "s3:PutObject",
      ]

      resources = [
        "${aws_s3_bucket.multiple_buckets[each.key].arn}/*",
      ]
    }
  }

  # Define a common policy for regions created after August 2022
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
      "${aws_s3_bucket.multiple_buckets[each.key].arn}/*",
    ]
  }
}

# IAM Policy Document for Load Balancer (LB) Log Delivery
data "aws_iam_policy_document" "lb_log_delivery" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if var.attach_lb_log_delivery_policy }

  # Define statements for LB log delivery
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
      "${aws_s3_bucket.multiple_buckets[each.key].arn}/*",
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
      aws_s3_bucket.multiple_buckets[each.key].arn,
    ]
  }
}

# IAM Policy Document for S3 Access Log Delivery
data "aws_iam_policy_document" "access_log_delivery" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if var.attach_access_log_delivery_policy }

  # Define statements for access log delivery
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
      "${aws_s3_bucket.multiple_buckets[each.key].arn}/*",
    ]

    # Define conditions based on input variables
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
      aws_s3_bucket.multiple_buckets[each.key].arn,
    ]
  }
}

# IAM Policy Document for Denying Insecure Transport
data "aws_iam_policy_document" "deny_insecure_transport" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if var.attach_deny_insecure_transport_policy }

  # Define statements for denying insecure transport
  statement {
    sid    = "denyInsecureTransport"
    effect = "Deny"

    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.multiple_buckets[each.key].arn,
      "${aws_s3_bucket.multiple_buckets[each.key].arn}/*",
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

# IAM Policy Document for Denying Outdated TLS
data "aws_iam_policy_document" "require_latest_tls" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if var.attach_require_latest_tls_policy }

  # Define statements for denying outdated TLS
  statement {
    sid    = "denyOutdatedTLS"
    effect = "Deny"

    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.multiple_buckets[each.key].arn,
      "${aws_s3_bucket.multiple_buckets[each.key].arn}/*",
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

# IAM Policy Document for Denying Incorrect Encryption Headers
data "aws_iam_policy_document" "deny_incorrect_encryption_headers" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if var.attach_deny_incorrect_encryption_headers }

  # Define statements for denying incorrect encryption headers
  statement {
    sid    = "denyIncorrectEncryptionHeaders"
    effect = "Deny"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.multiple_buckets[each.key].arn}/*"
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

# IAM Policy Document for Denying Incorrect KMS Key SSE
data "aws_iam_policy_document" "deny_incorrect_kms_key_sse" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if var.attach_deny_incorrect_kms_key_sse }

  # Define statements for denying incorrect KMS key SSE
  statement {
    sid    = "denyIncorrectKmsKeySse"
    effect = "Deny"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.multiple_buckets[each.key].arn}/*"
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

# IAM Policy Document for Denying Unencrypted Object Uploads
data "aws_iam_policy_document" "deny_unencrypted_object_uploads" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if var.attach_deny_unencrypted_object_uploads }

  # Define statements for denying unencrypted object uploads
  statement {
    sid    = "denyUnencryptedObjectUploads"
    effect = "Deny"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.multiple_buckets[each.key].arn}/*"
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

# IAM Policy Document for Allowing CloudFront Access
data "aws_iam_policy_document" "allow_cloudfront_access" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets }

  # Define statements for allowing CloudFront access
  statement {
    sid    = "allowCloudfrontAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.multiple_buckets[each.key].arn}/*"
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

# IAM Policy Document for Combining Policies
data "aws_iam_policy_document" "combined" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if local.attach_policy }

  # Combine policies based on input variables
  source_policy_documents = compact([
    var.attach_elb_log_delivery_policy ? data.aws_iam_policy_document.elb_log_delivery[each.key].json : "",
    var.attach_lb_log_delivery_policy ? data.aws_iam_policy_document.lb_log_delivery[each.key].json : "",
    var.attach_access_log_delivery_policy ? data.aws_iam_policy_document.access_log_delivery[each.key].json : "",
    var.attach_require_latest_tls_policy ? data.aws_iam_policy_document.require_latest_tls[each.key].json : "",
    var.attach_deny_insecure_transport_policy ? data.aws_iam_policy_document.deny_insecure_transport[each.key].json : "",
    var.attach_deny_unencrypted_object_uploads ? data.aws_iam_policy_document.deny_unencrypted_object_uploads[each.key].json : "",
    var.attach_deny_incorrect_kms_key_sse ? data.aws_iam_policy_document.deny_incorrect_kms_key_sse[each.key].json : "",
    var.attach_deny_incorrect_encryption_headers ? data.aws_iam_policy_document.deny_incorrect_encryption_headers[each.key].json : "",
    data.aws_iam_policy_document.allow_cloudfront_access[each.key].json,
    var.attach_policy ? var.policy : ""
  ])
}
