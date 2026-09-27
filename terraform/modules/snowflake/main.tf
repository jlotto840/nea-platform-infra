terraform {
  required_providers {
    snowflake = {
      source = "Snowflake-Labs/snowflake"
    }
  }
}

variable "name" {
  type = string
}

variable "database" {
  type = string
}

variable "schema" {
  type = string
}

variable "integration_role_arn" {
  type = string
}

variable "curated_bucket_name" {
  type = string
}

# Snowflake reads the curated zone through a storage integration (IAM role trust),
# so no AWS keys are ever stored in Snowflake or in this repository.
resource "snowflake_storage_integration" "curated" {
  name                      = "${var.name}_CURATED_INT"
  type                      = "EXTERNAL_STAGE"
  storage_provider          = "S3"
  enabled                   = true
  storage_aws_role_arn      = var.integration_role_arn
  storage_allowed_locations = ["s3://${var.curated_bucket_name}/"]
}

resource "snowflake_stage" "curated" {
  name                = "CURATED_STAGE"
  database            = var.database
  schema              = var.schema
  url                 = "s3://${var.curated_bucket_name}/"
  storage_integration = snowflake_storage_integration.curated.name
  comment             = "NEA curated zone (storage integration, no embedded credentials)"
}
