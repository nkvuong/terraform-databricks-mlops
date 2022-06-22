data "databricks_current_user" "staging_user" {
  provider = databricks.staging
}

data "databricks_current_user" "prod_user" {
  provider = databricks.prod
}

resource "databricks_group" "staging_sp_group" {
  provider     = databricks.staging
  display_name = "mlops-service-principals"
}

resource "databricks_permissions" "staging_token_usage" {
  provider      = databricks.staging
  authorization = "tokens"

  access_control {
    group_name       = databricks_group.staging_sp_group.display_name
    permission_level = "CAN_USE"
  }

  dynamic "access_control" {
    for_each = var.additional_token_usage_groups
    content {
      group_name       = access_control.value
      permission_level = "CAN_USE"
    }
  }
}

resource "databricks_group" "prod_sp_group" {
  provider     = databricks.prod
  display_name = "mlops-service-principals"
}

resource "databricks_permissions" "prod_token_usage" {
  provider      = databricks.prod
  authorization = "tokens"

  access_control {
    group_name       = databricks_group.prod_sp_group.display_name
    permission_level = "CAN_USE"
  }

  dynamic "access_control" {
    for_each = var.additional_token_usage_groups
    content {
      group_name       = access_control.value
      permission_level = "CAN_USE"
    }
  }
}

module "create_staging_sp" {
  source = "../azure-create-service-principal"
  providers = {
    databricks = databricks.staging
    azuread    = azuread
  }
  display_name    = "READ-only Model Registry Service Principal"
  group_name      = databricks_group.staging_sp_group.display_name
  azure_tenant_id = var.azure_tenant_id
  depends_on      = [databricks_permissions.staging_token_usage]
}

resource "databricks_token" "staging_sp_token" {
  provider         = databricks.staging_sp
  comment          = "PAT on behalf of ${module.create_staging_sp.service_principal_application_id}"
  lifetime_seconds = 8640000 // 100 day token
}

module "create_prod_sp" {
  source = "../azure-create-service-principal"
  providers = {
    databricks = databricks.prod
    azuread    = azuread
  }
  display_name    = "READ-only Model Registry Service Principal"
  group_name      = databricks_group.prod_sp_group.display_name
  azure_tenant_id = var.azure_tenant_id
  depends_on      = [databricks_permissions.prod_token_usage]
}

resource "databricks_token" "prod_sp_token" {
  provider         = databricks.prod_sp
  comment          = "PAT on behalf of ${module.create_prod_sp.service_principal_application_id}"
  lifetime_seconds = 8640000 // 100 day token
}

module "remote_model_registry_dev_to_staging" {
  source = "../remote-model-registry"
  providers = {
    databricks.local  = databricks.dev
    databricks.remote = databricks.staging
  }
  local_secret_scope_groups               = ["users"]
  local_secret_scope_name                 = "remote-mr-staging"
  local_secret_scope_prefix               = "staging"
  remote_service_principal_application_id = module.create_staging_sp.service_principal_application_id
  remote_service_principal_token          = databricks_token.staging_sp_token.token_value
  remote_workspace_id                     = var.staging_workspace_id
}

module "remote_model_registry_dev_to_prod" {
  source = "../remote-model-registry"
  providers = {
    databricks.local  = databricks.dev
    databricks.remote = databricks.prod
  }
  local_secret_scope_groups               = ["users"]
  local_secret_scope_name                 = "remote-mr-prod"
  local_secret_scope_prefix               = "prod"
  remote_service_principal_application_id = module.create_prod_sp.service_principal_application_id
  remote_service_principal_token          = databricks_token.prod_sp_token.token_value
  remote_workspace_id                     = var.prod_workspace_id
}

module "remote_model_registry_staging_to_prod" {
  source = "../remote-model-registry"
  providers = {
    databricks.local  = databricks.staging
    databricks.remote = databricks.prod
  }
  local_secret_scope_groups               = ["users"]
  local_secret_scope_name                 = "remote-mr-prod"
  local_secret_scope_prefix               = "prod"
  remote_service_principal_application_id = module.create_prod_sp.service_principal_application_id
  remote_service_principal_token          = databricks_token.prod_sp_token.token_value
  remote_workspace_id                     = var.prod_workspace_id
}
