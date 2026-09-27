output "raw_bucket" {
  value = module.data_lake.raw_bucket_name
}

output "curated_bucket" {
  value = module.data_lake.curated_bucket_name
}

output "core_db_endpoint" {
  value = module.database.endpoint
}

output "ingest_role_arn" {
  value = module.iam.ingest_role_arn
}

output "reporting_db_endpoint" {
  value = module.reporting.reporting_endpoint
}
