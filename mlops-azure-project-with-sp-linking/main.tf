data "databricks_group" "staging_sp_group" {
  provider     = databricks.staging
  display_name = "mlops-service-principals"
}

data "databricks_group" "prod_sp_group" {
  provider     = databricks.prod
  display_name = "mlops-service-principals"
}

module "link_staging_sp" {
  source = "../azure-link-service-principal"
  providers = {
    databricks = databricks.staging
  }
  display_name        = "READ-only Model Registry Service Principal"
  group_name          = data.databricks_group.staging_sp_group.display_name
  azure_client_id     = var.azure_staging_client_id
  aad_token           = var.azure_staging_aad_token
  azure_client_secret = var.azure_staging_client_secret
  azure_tenant_id     = var.azure_staging_tenant_id
}

module "link_prod_sp" {
  source = "../azure-link-service-principal"
  providers = {
    databricks = databricks.prod
  }
  display_name        = "READ-only Model Registry Service Principal"
  group_name          = data.databricks_group.prod_sp_group.display_name
  azure_client_id     = var.azure_prod_client_id
  aad_token           = var.azure_prod_aad_token
  azure_client_secret = var.azure_prod_client_secret
  azure_tenant_id     = var.azure_prod_tenant_id
}

resource "databricks_directory" "staging_directory" {
  provider = databricks.staging
  path     = var.project_directory_path
}

resource "databricks_permissions" "staging_directory_usage" {
  provider       = databricks.staging
  directory_path = databricks_directory.staging_directory.path

  access_control {
    service_principal_name = module.link_staging_sp.service_principal_application_id
    permission_level       = "CAN_MANAGE"
  }
}

resource "databricks_directory" "prod_directory" {
  provider = databricks.prod
  path     = var.project_directory_path
}

resource "databricks_permissions" "prod_directory_usage" {
  provider       = databricks.prod
  directory_path = databricks_directory.prod_directory.path

  access_control {
    service_principal_name = module.link_prod_sp.service_principal_application_id
    permission_level       = "CAN_MANAGE"
  }
}
