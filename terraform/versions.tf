terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.100"
    }
  }

  # State lives in the Meridian-managed state bucket; configured at init time with
  # -backend-config=environments/prod.backend.hcl (not committed).
  backend "s3" {}
}
