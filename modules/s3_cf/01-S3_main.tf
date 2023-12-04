locals {
  attach_policy = var.external_cloudfront_access_policy["enable"] || var.enable_cf || var.attach_require_latest_tls_policy || var.attach_access_log_delivery_policy || var.attach_elb_log_delivery_policy || var.attach_lb_log_delivery_policy || var.attach_deny_insecure_transport_policy || var.attach_deny_incorrect_encryption_headers || var.attach_deny_incorrect_kms_key_sse || var.attach_deny_unencrypted_object_uploads || var.attach_policy

}
resource "aws_s3_bucket" "multiple_buckets" {
  # checkov:skip=CKV_AWS_145: We are using Server-side encryption with Amazon S3 managed keys (SSE-S3)
  # checkov:skip=CKV_AWS_144: we don't need to have cross-region replication enabled in the meantime
  count  = length(var.s3_bucket_names) 
  bucket = var.s3_bucket_names[count.index]
  tags   = var.tags
}

resource "aws_s3_bucket_logging" "s3_logging" {
  count         = length(var.s3_bucket_names)
  bucket        = var.s3_bucket_names[count.index]
  target_bucket = aws_s3_bucket.multiple_buckets[count.index].id
  target_prefix = "log/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "multiple_buckets" {
  count  = length(var.s3_bucket_names)
  bucket = aws_s3_bucket.multiple_buckets[count.index].id
  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_s3_bucket_versioning" "multiple_buckets" {
  count  = length(var.s3_bucket_names)
  bucket = aws_s3_bucket.multiple_buckets[count.index].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "multiple_buckets" {
  count  = length(var.s3_bucket_names)
  bucket = aws_s3_bucket.multiple_buckets[count.index].id
  dynamic "rule" {
    for_each = var.rules

    content {
      id     = rule.key
      status = rule.value.status

      dynamic "noncurrent_version_expiration" {
        for_each = [rule.value.noncurrent_version_expiration]

        content {
          newer_noncurrent_versions = noncurrent_version_expiration.value.newer_noncurrent_versions
          noncurrent_days           = noncurrent_version_expiration.value.noncurrent_days
        }
      }
      dynamic "noncurrent_version_transition" {
        for_each = [rule.value.noncurrent_version_transition]

        content {
          newer_noncurrent_versions = noncurrent_version_transition.value.newer_noncurrent_versions
          noncurrent_days           = noncurrent_version_transition.value.noncurrent_days
          storage_class             = noncurrent_version_transition.value.storage_class
        }
      }
      dynamic "abort_incomplete_multipart_upload" {
        for_each = [rule.value.abort_incomplete_multipart_upload]

        content {
          days_after_initiation = abort_incomplete_multipart_upload.value.days_after_initiation
        }
      }
    }
  }
}


resource "aws_s3_bucket_ownership_controls" "this" {
  count  = length(var.s3_bucket_names)
  bucket = aws_s3_bucket.multiple_buckets[count.index].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "multiple_buckets_public_block" {
  count                   = length(var.s3_bucket_names)
  bucket                  = aws_s3_bucket.multiple_buckets[count.index].id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}


data "aws_iam_policy_document" "combined" {
  count = local.attach_policy ? 1 : 0

  source_policy_documents = compact([
    var.attach_elb_log_delivery_policy ? data.aws_iam_policy_document.elb_log_delivery[0].json : "",
    var.attach_lb_log_delivery_policy ? data.aws_iam_policy_document.lb_log_delivery[0].json : "",
    var.attach_access_log_delivery_policy ? data.aws_iam_policy_document.access_log_delivery[0].json : "",
    var.attach_require_latest_tls_policy ? data.aws_iam_policy_document.require_latest_tls[0].json : "",
    var.attach_deny_insecure_transport_policy ? data.aws_iam_policy_document.deny_insecure_transport[0].json : "",
    var.attach_deny_unencrypted_object_uploads ? data.aws_iam_policy_document.deny_unencrypted_object_uploads[0].json : "",
    var.attach_deny_incorrect_kms_key_sse ? data.aws_iam_policy_document.deny_incorrect_kms_key_sse[0].json : "",
    var.attach_deny_incorrect_encryption_headers ? data.aws_iam_policy_document.deny_incorrect_encryption_headers[0].json : "",
    var.enable_cf ? data.aws_iam_policy_document.allow_cloudfront_access[0].json : "",
    lookup(var.external_cloudfront_access_policy, "enable", 0) ? data.aws_iam_policy_document.allow_external_cloudfront_access[0].json : "",
    var.attach_policy ? var.policy : ""
  ])
}

resource "aws_s3_bucket_policy" "this" {
  count = local.attach_policy ? 1 : 0
  # Chain resources (s3_bucket -> s3_bucket_public_access_block -> s3_bucket_policy )
  bucket = aws_s3_bucket.multiple_buckets[0].id
  policy = data.aws_iam_policy_document.combined[0].json

  depends_on = [
    aws_s3_bucket_public_access_block.multiple_buckets_public_block
  ]
}

