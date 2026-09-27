provider "aws" {
  region = var.aws_region

  # Mandatory tags applied to every resource created through this provider
  # (OHIP tagging strategy: Application ID and Cost Center are mandatory).
  default_tags {
    tags = {
      ApplicationId      = var.application_id
      CostCenter         = var.cost_center
      Environment        = var.environment
      DataClassification = "PHI"
      Owner              = "meridian-nea-platform"
      ManagedBy          = "terraform"
    }
  }
}

# Credentials come from the pipeline's environment (SNOWFLAKE_* variables),
# never from this repository.
provider "snowflake" {}
