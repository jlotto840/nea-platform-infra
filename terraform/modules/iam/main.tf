variable "name" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "raw_bucket_arn" {
  type = string
}

variable "curated_bucket_arn" {
  type = string
}

variable "log_group_arns" {
  type = list(string)
}

variable "db_cluster_resource_id" {
  type = string
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# Role for the ingest workers: least privilege, scoped to the two data-lake zones,
# the platform key, its own log groups, and IAM database auth as the ingest_writer user.
resource "aws_iam_role" "ingest" {
  name = "${var.name}-ingest"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ingest" {
  name = "ingest-least-privilege"
  role = aws_iam_role.ingest.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadRawZone"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [var.raw_bucket_arn, "${var.raw_bucket_arn}/*"]
      },
      {
        Sid      = "WriteCuratedZone"
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
        Resource = [var.curated_bucket_arn, "${var.curated_bucket_arn}/*"]
      },
      {
        Sid      = "UsePlatformKey"
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = var.kms_key_arn
      },
      {
        Sid      = "WriteOwnLogs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = [for arn in var.log_group_arns : "${arn}:*"]
      },
      {
        Sid      = "IamDatabaseAuth"
        Effect   = "Allow"
        Action   = "rds-db:connect"
        Resource = "arn:aws:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dbuser:${var.db_cluster_resource_id}/ingest_writer"
      }
    ]
  })
}

output "ingest_role_arn" {
  value = aws_iam_role.ingest.arn
}
