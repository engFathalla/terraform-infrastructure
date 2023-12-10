# Create S3 buckets for failover
resource "aws_s3_bucket" "failover_buckets" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if buckets.enable_failover }
  bucket   = "${each.value.name}-failover"
  tags     = var.tags
  provider = aws.failover_region
}

# Enable S3 bucket logging for failover buckets
resource "aws_s3_bucket_logging" "failover_s3_logging" {
  for_each      = { for idx, buckets in var.s3_bucket : idx => buckets if buckets.enable_failover }
  bucket        = "${each.value.name}-failover"
  target_bucket = aws_s3_bucket.failover_buckets[each.key].id
  target_prefix = "log/"
  provider      = aws.failover_region
}

# Configure server-side encryption for failover buckets
resource "aws_s3_bucket_server_side_encryption_configuration" "failover_buckets" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if buckets.enable_failover }
  bucket   = aws_s3_bucket.failover_buckets[each.key].id
  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  provider = aws.failover_region
}

# Enable versioning for failover buckets
resource "aws_s3_bucket_versioning" "failover_buckets" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if buckets.enable_failover }
  bucket   = aws_s3_bucket.failover_buckets[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
  provider = aws.failover_region
}

# Configure lifecycle policies for failover buckets
resource "aws_s3_bucket_lifecycle_configuration" "failover_buckets" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if buckets.enable_failover }
  bucket   = aws_s3_bucket.failover_buckets[each.key].id
  rule {
    id     = "abort_incomplete_multipart_upload"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
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
  provider = aws.failover_region
}

# Configure ownership controls for failover buckets
resource "aws_s3_bucket_ownership_controls" "this_failover" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if buckets.enable_failover }
  bucket   = aws_s3_bucket.failover_buckets[each.key].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
  provider = aws.failover_region
}

# Configure public access block settings for failover buckets
resource "aws_s3_bucket_public_access_block" "failover_buckets_public_block" {
  for_each                = { for idx, buckets in var.s3_bucket : idx => buckets if buckets.enable_failover }
  bucket                  = aws_s3_bucket.failover_buckets[each.key].id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
  provider                = aws.failover_region
}

# Attach IAM policy to failover buckets
resource "aws_s3_bucket_policy" "this_failover" {
  for_each = { for idx, buckets in var.s3_bucket : idx => buckets if buckets.enable_failover }
  bucket   = aws_s3_bucket.failover_buckets[each.key].id
  policy   = data.aws_iam_policy_document.failover_combined[each.key].json

  depends_on = [
    aws_s3_bucket_public_access_block.failover_buckets_public_block
  ]
  provider = aws.failover_region
}
