# MLOps Azure Infrastructure Module with Service Principal Creation

This module sets up [multi-workspace model registry](https://docs.microsoft.com/en-us/azure/databricks/applications/machine-learning/manage-model-lifecycle/multiple-workspaces) between a development (dev) workspace, a staging workspace, and a production (prod) workspace, allowing READ access from dev/staging workspaces to staging & prod model registries.

The module performs this setup by creating AAD applications and associating them with newly created Azure Databricks service principals in the staging and prod workspaces, then giving them READ-only access to their respective model registries. It will also create secret scopes and store the necessary secrets in the dev and staging workspaces, and only give READ access to this secret scope to the `"users"` group and the generated service principals group. The output of this module will be the secret scope names and prefixes since these values are needed to be able to [access the remote model registry](https://docs.microsoft.com/en-us/azure/databricks/applications/machine-learning/manage-model-lifecycle/multiple-workspaces#specify-a-remote-registry).

**_NOTE:_**
1. The [Databricks providers](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs) that are passed into the module must be configured with workspace admin permissions.
2. The [Azure Active Directory (AzureAD) provider](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs) that is passed into the module must be configured with [Application.ReadWrite.All](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password#api-permissions) permissions to allow AAD application creation to link to an Azure Databricks service principal. This provider can be authenticated via an AAD [service principal](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/users-groups/service-principals#create-a-service-principal) with the Application.ReadWrite.All permission.
3. In order to create tokens for service principals, they are added to a group, which is then given `token_usage` [permission](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/permissions#token-usage). However, in order to set this permission, there must be [at least 1 personal access token in the workspace](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/permissions#token-usage), and this permission [strictly overwrites existing permissions](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/obo_token#example-usage). Currently, running this module will overwrite permissions to allow token usage only for members of the generated service principals group in the staging and prod workspaces. If additional groups are desired to have `token_usage` permissions, they can be set via the `additional_token_usage_groups` input variable.
4. The service principal tokens stored for remote model registry access are created with a default expiration of 100 days (8640000 seconds), and the module will need to be re-applied after this time to refresh the tokens.

## Usage
```hcl
provider "databricks" {
  alias = "dev"    # Authenticate using preferred method as described in Databricks provider
}

provider "databricks" {
  alias = "staging"     # Authenticate using preferred method as described in Databricks provider
}

provider "databricks" {
  alias = "prod"     # Authenticate using preferred method as described in Databricks provider
}

provider "azuread" {} # Authenticate using preferred method as described in AzureAD provider

module "mlops_azure_infrastructure_with_sp_creation" {
  source = "databrickslabs/mlops-azure-infrastructure-with-sp-creation/databricks"
  providers = {
    databricks.dev = databricks.dev
    databricks.staging = databricks.staging
    databricks.prod = databricks.prod
    azuread = azuread
  }
  staging_workspace_id          = "123456789"
  prod_workspace_id             = "987654321"
  azure_tenant_id               = "a1b2c3d4-e5f6-g7h8-i9j0-k9l8m7n6o5p4"
  additional_token_usage_groups = ["users"]     # This field is optional.
}
```

## Requirements
| Name | Version |
|------|---------|
|[terraform](https://registry.terraform.io/)|\>=1.1.6|
|[databricks](https://registry.terraform.io/providers/databrickslabs/databricks/0.5.8)|\>=0.5.8|
|[azuread](https://registry.terraform.io/providers/hashicorp/azuread/2.15.0)|\>=2.15.0|
|[python](https://www.python.org/downloads/release/python-380/)|\>=3.8|

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
|staging_workspace_id|Workspace ID of the staging workspace ([can be often found in the URL](https://docs.microsoft.com/en-us/azure/databricks/workspace/workspace-details#--workspace-instance-names-urls-and-ids)) used for remote model registry setup.|string|N/A|yes|
|prod_workspace_id|Workspace ID of the prod workspace ([can be often found in the URL](https://docs.microsoft.com/en-us/azure/databricks/workspace/workspace-details#--workspace-instance-names-urls-and-ids)) used for remote model registry setup.|string|N/A|yes|
|azure_tenant_id|The [Azure tenant ID](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/active-directory-how-to-find-tenant) of the AAD subscription. Must match the one used for the AzureAD Provider.|string|N/A|yes|
|additional_token_usage_groups|List of groups that should have token usage permissions in the staging and prod workspaces, along with the created service principal group (`mlops-service-principals`).|list(string)|\[\]|no|

## Outputs
| Name | Description | Type | Sensitive |
|------|-------------|------|---------|
|dev_secret_scope_name_for_staging|The name of the secret scope created in the dev workspace that is used for remote model registry access to the staging workspace.|string|no|
|dev_secret_scope_name_for_prod|The name of the secret scope created in the dev workspace that is used for remote model registry access to the prod workspace.|string|no|
|staging_secret_scope_name_for_prod|The name of the secret scope created in the staging workspace that is used for remote model registry access to the prod workspace.|string|no|
|dev_secret_scope_prefix_for_staging|The prefix used in the dev workspace secret scope for remote model registry access to the staging workspace.|string|no|
|dev_secret_scope_prefix_for_prod|The prefix used in the dev workspace secret scope for remote model registry access to the prod workspace.|string|no|
|staging_secret_scope_prefix_for_prod|The prefix used in the staging workspace secret scope for remote model registry access to the prod workspace.|string|no|

## Providers
| Name | Authentication | Use |
|------|-------------|----|
|databricks.dev|Provided by the user.|Generate all resources in the dev workspace.|
|databricks.staging|Provided by the user.|Generate all resources in the staging workspace.|
|databricks.prod|Provided by the user.|Generate all resources in the prod workspace.|
|azuread|Provided by the user. Can be authenticated via [azure_client_id, azure_client_secret, azure_tenant_id](https://registry.terraform.io/providers/hashicorp/azuread/2.15.0/docs/guides/service_principal_client_secret).| Create an AAD application and client secret for the service principal.|
|databricks.staging_sp|Authenticated via host and generated AAD token for service principal.|Obtain service principal PAT.|
|databricks.prod_sp|Authenticated via host and generated AAD token for service principal.|Obtain service principal PAT.|

## Resources
| Name | Type |
|------|------|
|databricks_current_user.staging_user|data source|
|databricks_current_user.prod_user|data source|
|databricks_group.staging_sp_group|resource|
|databricks_permissions.staging_token_usage|resource|
|databricks_group.prod_sp_group|resource|
|databricks_permissions.prod_token_usage|resource|
|databricks_token.staging_sp_token|resource|
|databricks_token.prod_sp_token|resource|
|azure-create-service-principal.create_staging_sp|module|
|azure-create-service-principal.create_prod_sp|module|
|remote-model-registry.remote_model_registry_dev_to_staging|module|
|remote-model-registry.remote_model_registry_dev_to_prod|module|
|remote-model-registry.remote_model_registry_staging_to_prod|module|

## Known Issues
- AAD token generation occasionally fails with `"HTTP Error 400: Bad Request"` but the query is not actually invalid.
    - Solution: Re-run `terraform apply` and the error should disappear.