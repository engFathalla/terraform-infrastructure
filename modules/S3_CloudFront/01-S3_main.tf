# Define local variable to determine if any policies should be attached
locals {
  attach_policy = var.attach_require_latest_tls_policy || var.attach_access_log_delivery_policy || var.attach_elb_log_delivery_policy || var.attach_lb_log_delivery_policy || var.attach_deny_insecure_transport_policy || var.attach_deny_incorrect_encryption_headers || var.attach_deny_incorrect_kms_key_sse || var.attach_deny_unencrypted_object_uploads || var.failover_attach_policy || var.attach_policy
}

# Create AWS S3 buckets using a for_each loop
resource "aws_s3_bucket" "multiple_buckets" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets }
  bucket   = each.value.name
  tags     = var.tags
}

# Enable logging for S3 buckets
resource "aws_s3_bucket_logging" "s3_logging" {
  for_each      = { for idx, buckets in var.s3_bucket : idx => buckets }
  bucket        = each.value.name
  target_bucket = aws_s3_bucket.multiple_buckets[each.key].id
  target_prefix = "log/"
}

# Configure server-side encryption for S3 buckets
resource "aws_s3_bucket_server_side_encryption_configuration" "multiple_buckets" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets }
  bucket   = aws_s3_bucket.multiple_buckets[each.key].id
  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enable versioning for S3 buckets
resource "aws_s3_bucket_versioning" "multiple_buckets" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets }
  bucket   = aws_s3_bucket.multiple_buckets[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configure lifecycle rules for S3 buckets
resource "aws_s3_bucket_lifecycle_configuration" "multiple_buckets" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets }
  bucket   = aws_s3_bucket.multiple_buckets[each.key].id
  rule {
    id     = "abort_incomplete_multipart_upload"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
  # Define dynamic rules based on input variables
  dynamic "rule" {
    for_each = var.rules

    content {
      id     = rule.key
      status = rule.value.status

      # Define noncurrent version expiration rules
      dynamic "noncurrent_version_expiration" {
        for_each = [rule.value.noncurrent_version_expiration]

        content {
          newer_noncurrent_versions = noncurrent_version_expiration.value.newer_noncurrent_versions
          noncurrent_days           = noncurrent_version_expiration.value.noncurrent_days
        }
      }
      # Define noncurrent version transition rules
      dynamic "noncurrent_version_transition" {
        for_each = [rule.value.noncurrent_version_transition]

        content {
          newer_noncurrent_versions = noncurrent_version_transition.value.newer_noncurrent_versions
          noncurrent_days           = noncurrent_version_transition.value.noncurrent_days
          storage_class             = noncurrent_version_transition.value.storage_class
        }
      }
      # Define abort incomplete multipart upload rules
      dynamic "abort_incomplete_multipart_upload" {
        for_each = [rule.value.abort_incomplete_multipart_upload]

        content {
          days_after_initiation = abort_incomplete_multipart_upload.value.days_after_initiation
        }
      }
    }
  }
}

# Configure S3 bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "this" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets }
  bucket   = aws_s3_bucket.multiple_buckets[each.key].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  # Uncomment the following dynamic blocks based on specific conditions
  # dynamic "rule" {
  #   for_each = length(each.value.logging_config) == 0 ?  [1] : []
  #   content {
  #     object_ownership = "BucketOwnerEnforced"
  #   }
  # }
  # dynamic "rule" {
  #   for_each = length(each.value.logging_config) > 0 ? [1] : []
  #   content {
  #     object_ownership = "BucketOwnerPreferred"
  #   }
  # }
}

# Configure ACL for S3 buckets that have logging enabled
resource "aws_s3_bucket_acl" "this" {
  for_each   = { for idx, buckets in var.s3_bucket : idx => buckets if length(buckets.logging_config) > 0 }
  bucket     = aws_s3_bucket.multiple_buckets[each.key].id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.this, aws_s3_bucket.multiple_buckets]
}

# Configure public access block settings for S3 buckets
resource "aws_s3_bucket_public_access_block" "multiple_buckets_public_block" {
  for_each                = { for idx, buckets in var.s3_bucket : idx => buckets }
  bucket                  = aws_s3_bucket.multiple_buckets[each.key].id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# Apply a bucket policy to S3 buckets based on attached policies
resource "aws_s3_bucket_policy" "this" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if local.attach_policy }
  # Chain resources (s3_bucket -> s3_bucket_public_access_block -> s3_bucket_policy )
  bucket = aws_s3_bucket.multiple_buckets[each.key].id
  policy = data.aws_iam_policy_document.combined[each.key].json

  depends_on = [
    aws_s3_bucket_public_access_block.multiple_buckets_public_block
  ]
}
