variable "aws_region" {
  description = "AWS region for the NEA platform."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (dev, test, prod)."
  type        = string
}

variable "application_id" {
  description = "OHIP-assigned Application ID (mandatory tag)."
  type        = string
}

variable "cost_center" {
  description = "Primary Cost Center (mandatory tag)."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "nea"
}

variable "vpc_id" {
  description = "VPC provided by the OHIP landing zone."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the database tier."
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Security group of the ingest workers allowed to reach the database."
  type        = string
}

variable "siem_firehose_arn" {
  description = "Kinesis Data Firehose stream that delivers logs to the OHIP SIEM."
  type        = string
}

variable "snowflake_database" {
  description = "Snowflake database that holds NEA data."
  type        = string
  default     = "NEA"
}

variable "snowflake_schema" {
  description = "Snowflake schema for raw landing tables."
  type        = string
  default     = "RAW"
}

variable "snowflake_integration_role_arn" {
  description = "IAM role Snowflake assumes through the storage integration."
  type        = string
}

variable "retention_days_raw" {
  description = "Days to keep raw-zone objects before archive (Section 7.12 retention schedule)."
  type        = number
  default     = 365
}
