# Databricks MLOps Terraform Modules

## Project Description
Doing MLOps on Databricks can be an involved procedure, so we have created these Terraform modules to simplify the journey.

### Parent Modules
- MLOps AWS Infrastructure
    - This module sets up [multi-workspace model registry](https://docs.databricks.com/applications/machine-learning/manage-model-lifecycle/multiple-workspaces.html#specify-a-remote-registry) between a development (dev) workspace, a staging workspace, and a production (prod) workspace, allowing READ access from dev/staging workspaces to staging & prod model registries.
    - Used for Databricks on AWS.
- MLOps AWS Project
    - This module creates and configures service principals with appropriate permissions and entitlements to run CI/CD for a project, and creates a workspace directory as a container for project-specific resources for the staging and prod workspaces.
    - Used for Databricks on AWS alongside the MLOps AWS Infrastructure module.
- MLOps Azure Infrastructure with Service Principal Creation
    - This module sets up [multi-workspace model registry](https://docs.microsoft.com/en-us/azure/databricks/applications/machine-learning/manage-model-lifecycle/multiple-workspaces) between a development (dev) workspace, a staging workspace, and a production (prod) workspace, allowing READ access from dev/staging workspaces to staging & prod model registries.
    - Used for Azure Databricks with AAD application creation. 
- MLOps Azure Infrastructure with Service Principal Linking
    - This module sets up [multi-workspace model registry](https://docs.microsoft.com/en-us/azure/databricks/applications/machine-learning/manage-model-lifecycle/multiple-workspaces) between a development (dev) workspace, a staging workspace, and a production (prod) workspace, allowing READ access from dev/staging workspaces to staging & prod model registries.
    - Used for Azure Databricks with pre-existing AAD application linking. 
- MLOps Azure Project with Service Principal Creation
    - This module creates and configures service principals with appropriate permissions and entitlements to run CI/CD for a project, and creates a workspace directory as a container for project-specific resources for the staging and prod workspaces.
    - Used for Azure Databricks with AAD application creation. 
- MLOps Azure Project with Service Principal Linking
    - This module creates and configures service principals with appropriate permissions and entitlements to run CI/CD for a project, and creates a workspace directory as a container for project-specific resources for the staging and prod workspaces.
    - Used for Azure Databricks with pre-existing AAD application linking. 

### Child Modules
- AWS Service Principal
    - This module will create a Databricks Service Principal in an AWS workspace, outputting its application ID and personal access token (PAT).
    - Used for Databricks on AWS.
- Azure Create Service Principal
    - This module will create an Azure Active Directory (AAD) Application and link it to a new Azure Databricks Service Principal in a workspace, outputting its application ID and AAD token.
    - Used for Azure Databricks with AAD application creation. 
- Azure Link Service Principal
    - This module will link an existing Azure Active Directory (AAD) Application to a new Azure Databricks Service Principal in a workspace, outputting its application ID and AAD token.
    - Used for Azure Databricks with pre-existing AAD application linking.
- Remote Model Registry
    - This module will set up remote model registry between a local Databricks workspace and a remote Databricks workspace, using a pre-created service principal in the remote workspace. It will create a secret scope and store the necessary secrets, and only give READ access to this secret scope to the groups in the user-provided list. It will also give registry-wide READ permissions to the remote service principal provided by the user in the remote workspace. The output of this module will be the local secret scope name and prefix since these two values are needed to be able to [access the remote model registry](https://docs.databricks.com/applications/machine-learning/manage-model-lifecycle/multiple-workspaces.html#specify-a-remote-registry).

## Project Support
Please note that all projects in the /databrickslabs github account are provided for your exploration only, and are not formally supported by Databricks with Service Level Agreements (SLAs).  They are provided AS-IS and we do not make any guarantees of any kind.  Please do not submit a support ticket relating to any issues arising from the use of these projects.

Any issues discovered through the use of this project should be filed as GitHub Issues on the Repo.  They will be reviewed as time permits, but there are no formal SLAs for support.

## Using the Project
Download Terraform, create configuration files as seen in the examples provided in the module READMEs, and call `terraform init/plan/apply`.
