resource "aws_s3_bucket" "dr_multiple_buckets" {
  # checkov:skip=CKV_AWS_145: We are using Server-side encryption with Amazon S3 managed keys (SSE-S3)
  # checkov:skip=CKV_AWS_144: we don't need to have cross-region replication enabled in the meantime
  count    = var.enable_dr ? length(var.s3_bucket_names) : 0 //count will be 3
  bucket   = "${var.s3_bucket_names[count.index]}-dr"
  tags     = var.tags
  provider = aws.region2
}

resource "aws_s3_bucket_logging" "dr_s3_logging" {
  count         = var.enable_dr ? length(var.s3_bucket_names) : 0
  bucket        = "${var.s3_bucket_names[count.index]}-dr"
  target_bucket = aws_s3_bucket.dr_multiple_buckets[count.index].id
  target_prefix = "log/"
  provider      = aws.region2
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dr_multiple_buckets" {
  count  = var.enable_dr ? length(var.s3_bucket_names) : 0
  bucket = aws_s3_bucket.dr_multiple_buckets[count.index].id
  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  provider = aws.region2
}

resource "aws_s3_bucket_versioning" "dr_multiple_buckets" {
  count  = var.enable_dr ? length(var.s3_bucket_names) : 0
  bucket = aws_s3_bucket.dr_multiple_buckets[count.index].id
  versioning_configuration {
    status = "Enabled"
  }
  provider = aws.region2
}

resource "aws_s3_bucket_lifecycle_configuration" "dr_multiple_buckets" {
  count  = var.enable_dr ? length(var.s3_bucket_names) : 0
  bucket = aws_s3_bucket.dr_multiple_buckets[count.index].id
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
  provider = aws.region2
}


resource "aws_s3_bucket_ownership_controls" "dr_this" {
  count  = var.enable_dr ? length(var.s3_bucket_names) : 0
  bucket = aws_s3_bucket.dr_multiple_buckets[count.index].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
  provider = aws.region2
}

resource "aws_s3_bucket_public_access_block" "dr_multiple_buckets_public_block" {
  count                   = var.enable_dr ? length(var.s3_bucket_names) : 0
  bucket                  = aws_s3_bucket.dr_multiple_buckets[count.index].id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
  provider                = aws.region2
}


data "aws_iam_policy_document" "dr_combined" {
  count = var.enable_dr && local.attach_policy ? 1 : 0

  source_policy_documents = compact([
    var.attach_elb_log_delivery_policy ? data.aws_iam_policy_document.dr_elb_log_delivery[0].json : "",
    var.attach_lb_log_delivery_policy ? data.aws_iam_policy_document.dr_lb_log_delivery[0].json : "",
    var.attach_access_log_delivery_policy ? data.aws_iam_policy_document.dr_access_log_delivery[0].json : "",
    var.attach_require_latest_tls_policy ? data.aws_iam_policy_document.dr_require_latest_tls[0].json : "",
    var.attach_deny_insecure_transport_policy ? data.aws_iam_policy_document.dr_deny_insecure_transport[0].json : "",
    var.attach_deny_unencrypted_object_uploads ? data.aws_iam_policy_document.dr_deny_unencrypted_object_uploads[0].json : "",
    var.attach_deny_incorrect_kms_key_sse ? data.aws_iam_policy_document.dr_deny_incorrect_kms_key_sse[0].json : "",
    var.attach_deny_incorrect_encryption_headers ? data.aws_iam_policy_document.dr_deny_incorrect_encryption_headers[0].json : "",
    var.enable_dr && var.enable_cf  ? data.aws_iam_policy_document.dr_allow_cloudfront_access[0].json : "",
    var.attach_policy ? var.policy : ""
  ])
  provider = aws.region2
}

resource "aws_s3_bucket_policy" "dr_this" {
  count = var.enable_dr && local.attach_policy ? 1 : 0
  # Chain resources (s3_bucket -> s3_bucket_public_access_block -> s3_bucket_policy )
  bucket = aws_s3_bucket.dr_multiple_buckets[0].id
  policy = data.aws_iam_policy_document.dr_combined[0].json

  depends_on = [
    aws_s3_bucket_public_access_block.dr_multiple_buckets_public_block
  ]
  provider = aws.region2
}

