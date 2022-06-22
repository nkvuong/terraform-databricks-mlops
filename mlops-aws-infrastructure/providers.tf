terraform {
  required_providers {
    databricks = {
      source                = "databrickslabs/databricks"
      version               = ">= 0.5.8"
      configuration_aliases = [databricks.dev, databricks.staging, databricks.prod]
    }
  }
}
