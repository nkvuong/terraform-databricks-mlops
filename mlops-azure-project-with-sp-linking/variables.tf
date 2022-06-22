variable "service_principal_name" {
  type        = string
  description = "The display name for the service principals."
}

variable "project_directory_path" {
  type        = string
  description = "Path/Name of Azure Databricks workspace directory to be created for the project. NOTE: The parent directories in the path must already be created."
}

variable "azure_staging_client_id" {
  type        = string
  description = "The client ID of the AAD service principal in the staging workspace that will be used to READ the model registry from the dev workspace."
}

variable "azure_staging_aad_token" {
  type        = string
  description = "The AAD token of the service principal in the staging workspace. This will need to be manually refreshed once it expires (often within several minutes). NOTE: Only this or both azure_staging_client_secret & azure_staging_tenant_id need to be provided."
  default     = null
  nullable    = true
}

variable "azure_staging_client_secret" {
  type        = string
  description = "The client secret of the AAD service principal in the staging workspace. NOTE: If azure_staging_aad_token is not provided, this and azure_staging_tenant_id must be provided to generate an AAD token."
  default     = null
  nullable    = true
}

variable "azure_staging_tenant_id" {
  type        = string
  description = "The tenant ID of the AAD service principal in the staging workspace. NOTE: If azure_staging_aad_token is not provided, this and azure_staging_client_secret must be provided to generate an AAD token."
  default     = null
  nullable    = true
}

variable "azure_prod_client_id" {
  type        = string
  description = "The client ID of the AAD service principal in the prod workspace that will be used to READ the model registry from the dev & staging workspaces."
}

variable "azure_prod_aad_token" {
  type        = string
  description = "The AAD token of the service principal in the prod workspace. This will need to be manually refreshed once it expires (often within several minutes). NOTE: Only this or both azure_prod_client_secret & azure_prod_tenant_id need to be provided."
  default     = null
  nullable    = true
}

variable "azure_prod_client_secret" {
  type        = string
  description = "The client secret of the AAD service principal in the prod workspace. NOTE: If azure_prod_aad_token is not provided, this and azure_prod_tenant_id must be provided to generate an AAD token."
  default     = null
  nullable    = true
}

variable "azure_prod_tenant_id" {
  type        = string
  description = "The tenant ID of the AAD service principal in the prod workspace. NOTE: If azure_prod_aad_token is not provided, this and azure_prod_client_secret must be provided to generate an AAD token."
  default     = null
  nullable    = true
}
