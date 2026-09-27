variable "name" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "retention_days_raw" {
  type = number
}

locals {
  zones = {
    raw     = "${var.name}-raw"
    curated = "${var.name}-curated"
  }
}

resource "aws_s3_bucket" "zone" {
  for_each = local.zones
  bucket   = each.value
}

resource "aws_s3_bucket_public_access_block" "zone" {
  for_each                = aws_s3_bucket.zone
  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "zone" {
  for_each = aws_s3_bucket.zone
  bucket   = each.value.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "zone" {
  for_each = aws_s3_bucket.zone
  bucket   = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle aligned with the Section 7.12 retention schedule.
resource "aws_s3_bucket_lifecycle_configuration" "zone" {
  for_each = aws_s3_bucket.zone
  bucket   = each.value.id

  rule {
    id     = "retention"
    status = "Enabled"
    filter {}

    transition {
      days          = var.retention_days_raw
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Deny any request that is not over TLS.
resource "aws_s3_bucket_policy" "zone" {
  for_each = aws_s3_bucket.zone
  bucket   = each.value.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [each.value.arn, "${each.value.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}

output "raw_bucket_arn" {
  value = aws_s3_bucket.zone["raw"].arn
}

output "curated_bucket_arn" {
  value = aws_s3_bucket.zone["curated"].arn
}

output "raw_bucket_name" {
  value = aws_s3_bucket.zone["raw"].bucket
}

output "curated_bucket_name" {
  value = aws_s3_bucket.zone["curated"].bucket
}
