# MLOps Azure Project Module with Service Principal Linking

In both of the specified staging and prod workspaces, this module:
* Links a [pre-existing AAD applications](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/users-groups/service-principals#create-a-service-principal) and associates it with a newly created Azure Databricks service principal, configuring appropriate permissions and entitlements to run CI/CD for a project. 
* Creates a workspace directory as a container for project-specific resources

The service principals are granted `CAN_MANAGE` permissions on the created workspace directories.

**_NOTE:_** 
1. The [Databricks providers](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs) that are passed into the module should be configured with workspace admin permissions.
2. The module assumes that one of the two Azure Infrastructure Modules has already been applied, namely that service principal groups with token usage permissions have been created with the name `"mlops-service-principals"`.
3. The service principal AAD tokens are short-lived (<60 minutes in most cases). If a long-lived token is desired, the AAD token can be used to authenticate into a Databricks provider and provision a personal access token (PAT) for the service principal.

## Usage
### Option 1: Authentication with Azure Client Secret and Tenant ID
This option will use the client secrets and tenant IDs to generate AAD tokens for authentication. The advantage to this approach is not having to manually generate short-lived AAD tokens (normally maximum lifetime of 60 minutes) each time this module needs to be used.

**_NOTE:_** This option requires that Python 3.8+ be installed to obtain the service principal's AAD token.
```hcl
provider "databricks" {
  alias = "staging"     # Authenticate using preferred method as described in Databricks provider
}

provider "databricks" {
  alias = "prod"     # Authenticate using preferred method as described in Databricks provider
}

module "mlops_azure_project_with_sp_linking" {
  source = "databrickslabs/mlops-azure-project-with-sp-linking/databricks"
  providers = {
    databricks.staging = databricks.staging
    databricks.prod = databricks.prod
  }
  service_principal_name      = "example-name"
  project_directory_path      = "/dir-name"
  azure_staging_client_id     = "k9l8m7n6o5-e5f6-g7h8-i9j0-a1b2c3d4p4"
  azure_staging_client_secret = var.azure_staging_client_secret     # This value is sensitive.
  azure_staging_tenant_id     = "a1b2c3d4-e5f6-g7h8-i9j0-k9l8m7n6o5p4"
  azure_prod_client_id        = "k9l8m7n6p4-e5f6-g7h8-i9j0-a1b2c3d4o5"
  azure_prod_client_secret    = var.azure_prod_client_secret     # This value is sensitive.
  azure_prod_tenant_id        = "a1b2c3d4-e5f6-g7h8-i9j0-k9l8m7n6o5p4"
}
```
### Option 2: Authentication with Azure Active Directory (AAD) Token
This option will use the provided AAD tokens for authentication. The advantage to this approach is not having to create/provide client secrets and tenant IDs.
```hcl
provider "databricks" {
  alias = "staging"     # Authenticate using preferred method as described in Databricks provider
}

provider "databricks" {
  alias = "prod"     # Authenticate using preferred method as described in Databricks provider
}

module "mlops_azure_project_with_sp_linking" {
  source = "databrickslabs/mlops-azure-project-with-sp-linking/databricks"
  providers = {
    databricks.staging = databricks.staging
    databricks.prod = databricks.prod
  }
  service_principal_name  = "example-name"
  project_directory_path  = "/dir-name"
  azure_staging_client_id = "k9l8m7n6o5-e5f6-g7h8-i9j0-a1b2c3d4p4"
  azure_staging_aad_token = var.azure_staging_aad_token     # This value is sensitive.
  azure_prod_client_id    = "k9l8m7n6p4-e5f6-g7h8-i9j0-a1b2c3d4o5"
  azure_prod_aad_token    = var.azure_prod_aad_token     # This value is sensitive.
}
```

### Usage example with Git credentials for service principal
This can be helpful for common use cases such as Git authorization for [Remote Git Jobs](https://docs.databricks.com/repos/jobs-remote-notebook.html).
```hcl
data "databricks_current_user" "staging_user" {
  provider = databricks.staging
}

data "databricks_current_user" "prod_user" {
  provider = databricks.prod
}

provider "databricks" {
  alias = "staging_sp"
  host  = data.databricks_current_user.staging_user.workspace_url
  token = module.mlops_azure_project_with_sp_linking.staging_service_principal_aad_token
}

provider "databricks" {
  alias = "prod_sp"
  host  = data.databricks_current_user.prod_user.workspace_url
  token = module.mlops_azure_project_with_sp_linking.prod_service_principal_aad_token
}

resource "databricks_git_credential" "staging_git" {
  provider              = databricks.staging_sp
  git_username          = var.git_username
  git_provider          = var.git_provider
  personal_access_token = var.git_token    # This should be configured with `repo` scope for Databricks Repos.
}

resource "databricks_git_credential" "prod_git" {
  provider              = databricks.prod_sp
  git_username          = var.git_username
  git_provider          = var.git_provider
  personal_access_token = var.git_token    # This should be configured with `repo` scope for Databricks Repos.
}
```

## Requirements
| Name | Version |
|------|---------|
|[terraform](https://registry.terraform.io/)|\>=1.1.6|
|[databricks](https://registry.terraform.io/providers/databrickslabs/databricks/0.5.8)|\>=0.5.8|
|[python](https://www.python.org/downloads/release/python-380/) \<Option 1\>|\>=3.8|

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
|service_principal_name|The display name for the service principals.|string|N/A|yes|
|project_directory_path|Path/Name of Azure Databricks workspace directory to be created for the project. NOTE: The parent directories in the path must already be created.|string|N/A|yes|
|azure_staging_client_id|The client ID of the AAD service principal in the staging workspace that will be used to READ the model registry from the dev workspace.|string|N/A|yes|
|azure_staging_aad_token|The AAD token of the service principal in the staging workspace. This will need to be manually refreshed once it expires (often within several minutes). NOTE: Only this or both `azure_staging_client_secret` & `azure_staging_tenant_id` need to be provided.|string|null|no|
|azure_staging_client_secret|The client secret of the AAD service principal in the staging workspace. NOTE: If `azure_staging_aad_token` is not provided, this and `azure_staging_tenant_id` must be provided to generate an AAD token.|string|null|no|
|azure_staging_tenant_id|The tenant ID of the AAD service principal in the staging workspace. NOTE: If `azure_staging_aad_token` is not provided, this and `azure_staging_client_secret` must be provided to generate an AAD token.|string|null|no|
|azure_prod_client_id|The client ID of the AAD service principal in the prod workspace that will be used to READ the model registry from the dev & staging workspaces.|string|N/A|yes|
|azure_prod_aad_token|The AAD token of the service principal in the prod workspace. This will need to be manually refreshed once it expires (often within several minutes). NOTE: Only this or both `azure_prod_client_secret` & `azure_prod_tenant_id` need to be provided.|string|null|no|
|azure_prod_client_secret|The client secret of the AAD service principal in the prod workspace. NOTE: If `azure_prod_aad_token` is not provided, this and `azure_prod_tenant_id` must be provided to generate an AAD token.|string|null|no|
|azure_prod_tenant_id|The tenant ID of the AAD service principal in the prod workspace. NOTE: If `azure_prod_aad_token` is not provided, this and `azure_prod_client_secret` must be provided to generate an AAD token.|string|null|no|

## Outputs
| Name | Description | Type | Sensitive |
|------|-------------|------|---------|
|project_directory_path|Path/Name of Azure Databricks workspace directory created for the project.|string|no|
|staging_service_principal_application_id|Application ID of the created Azure Databricks service principal in the staging workspace. Identical to the Azure client ID of the linked AAD application associated with the service principal.|string|no|
|staging_service_principal_aad_token|Sensitive AAD token value of the created Azure Databricks service principal in the staging workspace.|string|yes|
|prod_service_principal_application_id|Application ID of the created Azure Databricks service principal in the prod workspace. Identical to the Azure client ID of the linked AAD application associated with the service principal.|string|no|
|prod_service_principal_aad_token|Sensitive AAD token value of the created Azure Databricks service principal in the prod workspace.|string|yes|

## Providers
| Name | Authentication | Use |
|------|-------------|----|
|databricks.staging|Provided by the user.|Create group, directory, and service principal module in the staging workspace.|
|databricks.prod|Provided by the user.|Create group, directory, and service principal module in the prod workspace.|

## Resources
| Name | Type |
|------|------|
|databricks_group.staging_sp_group|data source|
|databricks_group.prod_sp_group|data source|
|databricks_directory.staging_directory|resource|
|databricks_permissions.staging_directory_usage|resource|
|databricks_directory.prod_directory|resource|
|databricks_permissions.prod_directory_usage|resource|
|azure-link-service-principal.link_staging_sp|module|
|azure-link-service-principal.link_prod_sp|module|

## Known Issues
- AAD token generation occasionally fails with `"HTTP Error 400: Bad Request"` but the query is not actually invalid.
    - Solution: Re-run `terraform apply` and the error should disappear.