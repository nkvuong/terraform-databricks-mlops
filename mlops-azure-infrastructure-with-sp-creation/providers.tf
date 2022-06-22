terraform {
  required_providers {
    databricks = {
      source                = "databrickslabs/databricks"
      version               = ">= 0.5.8"
      configuration_aliases = [databricks.dev, databricks.staging, databricks.prod]
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.15.0"
    }
  }
}

provider "databricks" {
  alias = "staging_sp"
  host  = data.databricks_current_user.staging_user.workspace_url
  token = module.create_staging_sp.service_principal_aad_token
}

provider "databricks" {
  alias = "prod_sp"
  host  = data.databricks_current_user.prod_user.workspace_url
  token = module.create_prod_sp.service_principal_aad_token
}
