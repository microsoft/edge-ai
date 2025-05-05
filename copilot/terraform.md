# Terraform Instructions

You are an expert in Terraform Infrastructure as Code (IaC) with deep knowledge of Azure resources.
Reference `general.instructions.md` for details on components and blueprints.

Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently. This document provides standards and conventions for Terraform development in this project.

You will ALWAYS think hard about terraform instructions and established conventions.

<!-- <table-of-contents> -->
## Table of Contents

- [Terraform CI Directories](#terraform-ci-directories) <!-- <example-terraform-ci> -->
- [Terraform Component Structure](#terraform-component-structure) <!-- <example-terraform-component-structure> -->
- [Terraform Component Files Organization](#terraform-component-files-organization)
- [Terraform Blueprint Structure](#terraform-blueprint-structure) <!-- <example-terraform-blueprint-structure> -->
- [Terraform Coding Conventions](#terraform-coding-conventions)
  - [Reference and Validation](#reference-and-validation)
  - [Terraform General Conventions](#terraform-general-conventions) <!-- <terraform-general-conventions> -->
    - [File and Naming Standards](#file-and-naming-standards)
    - [Documentation and Comments](#documentation-and-comments)
    - [Variables and Parameters](#variables-and-parameters)
    - [Module Structure](#module-structure)
    - [Resource Naming](#resource-naming)
    - [Outputs](#outputs)
    - [Component-Specific Conventions](#component-specific-conventions)
    - [Enforcing Conventions](#enforcing-conventions)
  - [Terraform Main File Organization](#terraform-main-file-organization) <!-- <component-main-tf-example> -->
  - [Terraform Variables Organization](#terraform-variables-organization) <!-- <component-variables-tf-example> -->
  - [Terraform Outputs Organization](#terraform-outputs-organization) <!-- <outputs-tf-example> -->
<!-- </table-of-contents> -->

## Terraform CI Directories

<!-- <example-terraform-ci> -->
Example `ci/main.tf`:

```terraform
// Defer computation to prevent `data` objects from querying for state on `terraform plan`.
resource "terraform_data" "defer" {
  input = {
    resource_group_name = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "aio" {
  name = terraform_data.defer.output.resource_group_name
}

module "ci" {
  source = "../../terraform"

  resource_prefix    = var.resource_prefix
  environment        = var.environment
  instance           = var.instance
  aio_resource_group = data.azurerm_resource_group.aio
  location           = var.location
}
```

Example `ci/variables.tf`:

```terraform
/*
 * Required Variables
 */

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z][-a-zA-Z0-9]*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes. Must start with an alphabetic character."
  }
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc..."
  default     = "001"
}
```

Example `ci/versions.tf`:

```terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.8.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 3.0.2"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.2.0"
    }
  }
  required_version = ">= 1.9.8, < 2.0"
}

provider "azurerm" {
  storage_use_azuread = true
  features {}
}
```
<!-- </example-terraform-ci> -->

## Terraform Component Structure

<!-- <example-terraform-component-structure> -->
```plain
src/
  000-cloud/
    010-security-identity/
      terraform/          # This is a COMPONENT MODULE
        main.tf           # Main orchestration file
        variables.tf      # Variables for this component and internal modules
        variables.core.tf # Core variables, always the same
        variables.deps.tf # Dependencies from other components (Optional)
        outputs.tf        # Component and internal module outputs
        versions.tf       # Required terraform providers for this component
        modules/
          key-vault/      # This is an INTERNAL MODULE
            main.tf
            variables.tf  # Variables for this internal module, has no defaults
            outputs.tf    # Outputs to be used by component to call other internal modules or just output
      ci/
        terraform/        # This is a CI TERRAFORM DIRECTORY
          main.tf         # CI wrapper for deployment
          variables.tf    # Only minimum required variables
          versions.tf     # Includes provider "azurerm" block
```
<!-- </example-terraform-component-structure> -->

## Terraform Component Files Organization

ALWAYS use consistent file organization(not limited to these files):

1. `main.tf` - Primary resource definitions and orchestration
2. `variables.tf` - Optional and required variables (including defaults for components)
3. `variables.core.tf` - Core variables, always the same variables for every component
4. `variables.deps.tf` - (Optional) Dependencies from other components as objects
5. `variables.<module>.tf` - (Optional) Module-specific variables, useful with many variables
6. `outputs.tf` - Component and internal module outputs for other components or internal modules
7. `versions.tf` - Required terraform providers for this component

## Terraform Blueprint Structure

Blueprints compose multiple components into complete IaC stamps:

<!-- <example-terraform-blueprint-structure> -->
```plain
blueprints/
  full-single-node-cluster/
    terraform/            # This is a BLUEPRINT MODULE
      main.tf             # Calls multiple COMPONENT MODULES but NEVER INTERNAL MODULES
      variables.tf        # Sensible variables to construct locals or pass to components
      outputs.tf          # Outputs from components
      versions.tf         # Includes provider "azurerm" block
    README.md             # Contains important deployment instructions
```
<!-- </example-terraform-blueprint-structure> -->

## Terraform Coding Conventions

### Reference and Validation

- ALWAYS search the codebase for existing Terraform resources to use as a reference when editing
- When no reference exists:
  1. Use the `#fetch` tool with the HashiCorp Registry to find the latest documentation for the resource:
     - Example URL format: `https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/{resource_name}`
     - Example: `https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry`
  2. Always check for deprecated fields and use the latest recommended properties
  3. Check for any specific provider version requirements
  4. Review examples to understand common usage patterns
- For `azapi` resources (only when no corresponding `azurerm` resource exists):
  1. Use the `#fetch` tool with the Azure ARM template reference documentation:
     - Example URL format: `https://learn.microsoft.com/en-us/azure/templates/{resource-provider}/{resource-type}?pivots=deployment-language-terraform`
     - Example: `https://learn.microsoft.com/en-us/azure/templates/microsoft.iotoperations/instances/dataflowendpoints?pivots=deployment-language-terraform`
  2. Extract the resource type in the format needed for `azapi`: `type = "Microsoft.IoTOperations/instances/dataflowEndpoints@<apiVersion>"`
  3. Use the documentation to identify required properties for the `body` parameter
  4. ALWAYS use the most recent API version available
  5. Example usage pattern for Azure IoT Operations dataflow endpoint:

     ```terraform
     resource "azapi_resource" "dataflow_endpoint" {
       type      = "Microsoft.IoTOperations/instances/dataflowEndpoints@2025-04-01"
       name      = "dfe-eh-${var.resource_prefix}-${var.environment}-sample-${var.instance}"
       parent_id = var.aio_instance.id

       body = {
         extendedLocation = {
           type = "CustomLocation"
           name = var.custom_location_id
         }
         properties = {
           endpointType = "Kafka"
           kafkaSettings = {
             host = "${var.event_hub.namespace_name}.servicebus.windows.net:9093"
             batching = {
               latencyMs   = 0
               maxMessages = 100
             }
             tls = {
               mode = "Enabled"
             }
             authentication = {
               method = "UserAssignedManagedIdentity"
               userAssignedManagedIdentitySettings = {
                 tenantId = var.aio_uami_tenant_id
                 clientId = var.aio_uami_client_id
               }
             }
           }
         }
       }
     }
     ```

- After making edits:
  1. Run `terraform fmt` to ensure proper formatting
  2. Run `terraform validate` to check for syntax and validation errors
  3. Verify VS Code's information, warnings, and errors for Terraform
  4. Fix all validation issues before committing changes
- DO use source code comments to reference documentation links for complex or non-obvious resource configurations:

  ```terraform
  // Ref: https://learn.microsoft.com/en-us/azure/templates/microsoft.iotoperations/instances/dataflowendpoints?pivots=deployment-language-terraform
  ```

### Terraform General Conventions

<!-- <terraform-general-conventions> -->
#### File and Naming Standards

- DO use `kebab-case` for file and folder names
- DO use `snake_case` for resource names and variables
- DO format code according to Terraform standards (`terraform fmt`)
- NEVER use deprecated properties on Terraform resources

#### Documentation and Comments

- DO use `//` for single-line comments or `/* */` for multi-line comments, NEVER use the `#` symbol
- DO include a markdown-formatted comment at the TOP of EVERY `main.tf` file
- DO provide descriptive `description` for all variables and outputs that ends with a period
- DO add helpful comments that clarify non-obvious code (e.g., references to docs)
- DON'T add useless comments that just describe what the code already clearly shows

#### Variables and Parameters

- DO specify `type` for all variables
- DO start boolean variables with `should_` or `is_`
- DO NOT add defaults to required variables
- DO include fallback values in descriptions: "Otherwise, 'id-{resource_prefix}-{environment}-{instance}'"
- DO sort variables alphabetically within each functional grouping
- DO use `try()`, `coalesce()`, and other Terraform functions instead of ternary operators
- DO provide variables for common settings
- DO include all required parameters and validate them
- DO use proper resource references to establish dependencies
- DON'T use ternary operators (`? :`), unless there is no other option such as `for_each = var.arc_onboarding_identity_id != null ? [1] : []`

#### Module Structure

- DON'T create provider blocks in component or internal modules
- DON'T modify provider blocks except in `blueprints/`, `ci/`, or `tests/` directories
- DON'T reference modules in ways that violate the module relationship rules

#### Resource Naming

- DO follow [Azure resource naming conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- DO follow these patterns for default resource names:
  - Hyphens allowed: `{resource_abbreviation}-${var.resource_prefix}-{optional_extra}-${var.environment}-${var.instance}`
  - Hyphens not allowed: `{resource_abbreviation}${var.resource_prefix}{optional_extra}${var.environment}${var.instance}`
  - Name length restriction: `'{resource_abbreviation}{optional_extra}${random_string.resource}'`
- Examples:
  - `id-${var.resource_prefix}-arc-${var.environment}-${var.instance}` for Identity
  - `st${random_string.random_clean_postfix}` for Storage Account
  - `acr${var.resource_prefix}${var.environment}${var.instance}` for Container Registry

#### Outputs

- DO output resources as objects with necessary fields that can be provided as variables to other components
- DO set `sensitive = true` for secrets
- DO provide helpful descriptions
- DO use functions like `try()` or `coalesce()`
- DON'T use ternary operators if possible

#### Component-Specific Conventions

For Components ONLY:

- DO provide defaults for variables that can have defaults
- DO provide validation for variables when conditions are known
- DO place resources in `main.tf`
- NEVER reference another component directly
  - EXPECT that other component resource outputs will be provided as variables
- NEVER reference another component's internal modules directly
  - EXPECT that other component's internal module's resources will be outputs
- DO receive existing resources as objects with only necessary fields in `variables.dep.tf`

For Internal modules ONLY:

- NEVER provide defaults for variables
  - Components should include variables and defaults for internal modules
- NEVER provide `validation` blocks for variables
- DO place resources in `{component_name}/terraform/modules/{module_name}/main.tf`
- NEVER use a component or another component's internal modules

#### Enforcing Conventions

You should ALWAYS ensure terraform conventions are being followed:

- CONTINUOUSLY evaluate if your changes follow terraform conventions
- Make changes to any and all places that are not following terraform conventions
- If a user's change conflicts with any terraform convention, suggest an update to the conventions
  - DON'T make any changes to the terraform conventions yourself
  - ONLY suggest an exact change as a response to the user
<!-- </terraform-general-conventions> -->

### Terraform Main File Organization

For all `main.tf` files, follow this consistent organization:

1. **Required**: Markdown formatted `/** */` comment at the top that includes:
   - Name of the component or internal module as a Title
   - Description of the component or internal module
2. Local variables in one `locals` block, grouped by functionality
3. `data` resources, grouped by functionality
4. `resource` resources, grouped by functionality
5. `module` resources, grouped by functionality

Each section should be clearly separated and logically organized.

Example:

<!-- <component-main-tf-example> -->
```terraform
/**
 * # CNCF Cluster
 *
 * Sets up and deploys a script to a VM host that will setup the cluster,
 * Arc connect the cluster, Add cluster admins to the cluster, enable workload identity,
 * install extensions for cluster connect and custom locations.
 */

locals {
  arc_resource_name    = "arck-${var.resource_prefix}-${var.environment}-${var.instance}"
  custom_locations_oid = try(coalesce(var.custom_locations_oid, data.azuread_service_principal.custom_locations[0].object_id), "")
  current_user_oid     = var.should_add_current_user_cluster_admin ? data.azurerm_client_config.current.object_id : null
}

data "azurerm_client_config" "current" {
}

data "azuread_service_principal" "custom_locations" {
  count = alltrue([var.should_get_custom_locations_oid, var.custom_locations_oid == null]) ? 1 : 0

  // ref: https://learn.microsoft.com/azure/iot-operations/deploy-iot-ops/howto-prepare-cluster?tabs=ubuntu#arc-enable-your-cluster
  client_id = "bc313c14-388c-4e7d-a58e-70017303ee3b" #gitleaks:allow
}

data "azapi_resource" "arc_connected_cluster" {
  count = var.should_deploy_script_to_vm ? 1 : 0

  type      = "Microsoft.Kubernetes/connectedClusters@2024-01-01"
  parent_id = var.resource_group.id
  name      = local.arc_resource_name

  depends_on = [module.ubuntu_k3s]

  response_export_values = ["name", "id", "location", "properties.oidcIssuerProfile.issuerUrl"]
}

resource "azurerm_role_assignment" "connected_machine_onboarding" {
  count = var.should_assign_roles ? 1 : 0

  principal_id         = try(var.arc_onboarding_identity.principal_id, var.arc_onboarding_sp.object_id)
  role_definition_name = "Kubernetes Cluster - Azure Arc Onboarding"
  scope                = var.resource_group.id
  // BUG: Role is never created for a new SP w/o this field: https://github.com/hashicorp/terraform-provider-azurerm/issues/11417
  skip_service_principal_aad_check = true
}

module "ubuntu_k3s" {
  source = "./modules/ubuntu-k3s"

  depends_on = [azurerm_role_assignment.connected_machine_onboarding]

  aio_resource_group                   = var.resource_group
  arc_onboarding_sp                    = var.arc_onboarding_sp
  arc_resource_name                    = local.arc_resource_name
  arc_tenant_id                        = data.azurerm_client_config.current.tenant_id
  cluster_admin_oid                    = try(coalesce(var.cluster_admin_oid, local.current_user_oid), null)
  custom_locations_oid                 = local.custom_locations_oid
  should_enable_arc_auto_upgrade       = var.should_enable_arc_auto_upgrade
  environment                          = var.environment
  cluster_node_virtual_machines        = var.cluster_node_virtual_machines
  cluster_server_ip                    = var.cluster_server_ip
  cluster_server_token                 = var.cluster_server_token
  cluster_server_virtual_machine       = var.cluster_server_virtual_machine
  script_output_filepath               = var.script_output_filepath
  should_deploy_script_to_vm           = var.should_deploy_script_to_vm
  should_generate_cluster_server_token = var.should_generate_cluster_server_token
  should_output_cluster_node_script    = var.should_output_cluster_node_script
  should_output_cluster_server_script  = var.should_output_cluster_server_script
  should_skip_az_cli_login             = var.should_skip_az_cli_login
  should_skip_installing_az_cli        = var.should_skip_installing_az_cli
  cluster_server_host_machine_username = coalesce(var.cluster_server_host_machine_username, var.resource_prefix)
}
```
<!-- </component-main-tf-example> -->

### Terraform Variables Organization

For all `variables.tf` or `variables.*.tf` files, follow this consistent organization:

1. Required variables with no defaults grouped at the top
2. Optional variables grouped by functionality
3. Each group should have a clear comment header
4. Variables within each group should be alphabetically sorted

Example:

<!-- <component-variables-tf-example> -->
```terraform
/*
 *  Azure Arc Parameters - Required
 */

variable "should_get_custom_locations_oid" {
  type        = bool
  description = <<-EOF
    Whether to get Custom Locations Object ID using Terraform's azuread provider. (Otherwise, provided by
    'custom_locations_oid' or `az connectedk8s enable-features` for custom-locations on cluster setup if not provided.)
EOF
}

/*
 * File System Parameters - Optional
 */

variable "script_output_filepath" {
  type        = string
  description = "The location of where to write out the script file. (Otherwise, '{path.root}/out')"
  default     = null
}

/*
 *  Azure Arc Parameters - Optional
 */

variable "custom_locations_oid" {
  type        = string
  description = <<-EOF
    The object id of the Custom Locations Entra ID application for your tenant.
    If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.

    ```sh
    az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
    ```
EOF
  default     = null
}

variable "should_enable_arc_auto_upgrade" {
  type        = bool
  description = "Enable or disable auto-upgrades of Arc agents. (Otherwise, 'false' for 'env=prod' else 'true' for all other envs)."
  default     = null
}

/*
 * Cluster and Host Machine Parameters - Optional
 */

variable "cluster_admin_oid" {
  type        = string
  description = "The Object ID that will be given cluster-admin permissions with the new cluster. (Otherwise, current logged in user if 'should_add_current_user_cluster_admin=true')"
  default     = null
}

variable "cluster_server_ip" {
  type        = string
  description = "The IP address for the server for the cluster. (Needed for mult-node cluster)"
  default     = null
}

variable "cluster_server_token" {
  type        = string
  description = "The token that will be given to the server for the cluster or used by the agent nodes to connect them to the cluster. (ex. <https://docs.k3s.io/cli/token)>"
  default     = null
  sensitive   = true
}
```
<!-- </component-variables-tf-example> -->

### Terraform Outputs Organization

For all `outputs.tf` files, follow this consistent organization:

1. Outputs grouped by functionality with clear comment headers
2. Outputs sorted alphabetically within each group
3. Consistent field order: `description`, `value`, `sensitive` (if needed)

Example:

<!-- <outputs-tf-example> -->
```terraform
/*
 * Key Vault Outputs
 */

output "key_vault" {
  description = "The Key Vault."
  value       = try(module.key_vault[0].key_vault, null)
}

/*
 * Identity Outputs
 */

output "arc_onboarding_sp" {
  description = "The Service Principal for Arc Onboarding a cluster."
  value       = try(module.identity[0].arc_onboarding_sp, null)
  sensitive   = true
}

output "secret_sync_identity" {
  description = "The Identity for the Secret Sync Extension."
  value       = try(module.identity[0].secret_sync_identity, null)
}

/*
 * Observability Outputs
 */

output "logs_data_collection_rule" {
  description = "The data collection rules that will determine what data to collect."
  value       = azurerm_monitor_data_collection_rule.logs_data_collection_rule
  sensitive   = true
}

/*
 * Arc Connected Cluster Outputs
 */

output "azure_arc_proxy_command" {
  description = "The AZ CLI command to Arc Connect Proxy to the cluster."
  value       = "az connectedk8s proxy -n ${local.arc_resource_name} -g ${var.resource_group.name}"
}

output "arc_connected_cluster" {
  description = "The Arc resource for the connected cluster."
  value       = try(data.azapi_resource.arc_connected_cluster[0].output, null)
}
```
<!-- </outputs-tf-example> -->
