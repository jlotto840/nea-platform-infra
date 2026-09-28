locals {
  name = "${var.name_prefix}-${var.environment}"
}

data "aws_caller_identity" "current" {}

# Customer-managed key for all NEA data at rest (S3, Aurora, CloudWatch Logs).
resource "aws_kms_key" "platform" {
  description             = "${local.name} platform data key"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.kms.json
}

resource "aws_kms_alias" "platform" {
  name          = "alias/${local.name}-platform"
  target_key_id = aws_kms_key.platform.key_id
}

data "aws_iam_policy_document" "kms" {
  statement {
    sid       = "AccountAdministration"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid       = "CloudWatchLogsEncryption"
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
    }
  }
}

module "logging" {
  source            = "./modules/logging"
  name              = local.name
  kms_key_arn       = aws_kms_key.platform.arn
  siem_firehose_arn = var.siem_firehose_arn
  log_group_names = [
    "/nea/${var.environment}/ingest",
    "/aws/rds/cluster/${local.name}-core/postgresql",
  ]
}

module "data_lake" {
  source             = "./modules/data_lake"
  name               = local.name
  kms_key_arn        = aws_kms_key.platform.arn
  retention_days_raw = var.retention_days_raw
}

module "database" {
  source                = "./modules/database"
  name                  = "${local.name}-core"
  kms_key_arn           = aws_kms_key.platform.arn
  vpc_id                = var.vpc_id
  subnet_ids            = var.private_subnet_ids
  app_security_group_id = var.app_security_group_id

  # Log group is created (with SIEM subscription) before the cluster exports to it.
  depends_on = [module.logging]
}

module "iam" {
  source                 = "./modules/iam"
  name                   = local.name
  kms_key_arn            = aws_kms_key.platform.arn
  raw_bucket_arn         = module.data_lake.raw_bucket_arn
  curated_bucket_arn     = module.data_lake.curated_bucket_arn
  log_group_arns         = module.logging.log_group_arns
  db_cluster_resource_id = module.database.cluster_resource_id
}

module "snowflake" {
  source               = "./modules/snowflake"
  name                 = upper(replace(local.name, "-", "_"))
  database             = var.snowflake_database
  schema               = var.snowflake_schema
  integration_role_arn = var.snowflake_integration_role_arn
  curated_bucket_name  = module.data_lake.curated_bucket_name
}

module "reporting" {
  source = "./modules/reporting"
  providers = {
    aws = aws.reporting
  }
  name                  = local.name
  vpc_id                = var.vpc_id
  subnet_ids            = var.private_subnet_ids
  app_security_group_id = var.app_security_group_id
  db_password           = var.reporting_db_password
  snowflake_database    = var.snowflake_database
  snowflake_schema      = var.snowflake_schema
}
