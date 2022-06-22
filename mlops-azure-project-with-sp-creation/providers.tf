terraform {
  required_providers {
    databricks = {
      source                = "databrickslabs/databricks"
      version               = ">= 0.5.8"
      configuration_aliases = [databricks.staging, databricks.prod]
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.15.0"
    }
  }
}
