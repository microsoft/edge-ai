# Terraform Coding Standards

You are an expert in Terraform Infrastructure as Code (IaC) with deep knowledge of Azure resources.

This file contains detailed coding conventions and file organization standards for Terraform.

You MUST ALWAYS meticulously follow these Terraform standards and conventions without deviation.

<!-- <table-of-contents> -->

## Table of Contents

- [Terraform Coding Standards](#terraform-coding-standards)
  - [Table of Contents](#table-of-contents)
  - [Terraform Coding Conventions](#terraform-coding-conventions)
    - [Terraform General Conventions](#terraform-general-conventions)
      - [File and Naming Standards](#file-and-naming-standards)
      - [Documentation and Comments](#documentation-and-comments)
      - [Variables and Parameters](#variables-and-parameters)
      - [Variable Description Standards](#variable-description-standards)
      - [Module Structure](#module-structure)
      - [Deferred Data Resources](#deferred-data-resources)
      - [Resource Naming](#resource-naming)
      - [Outputs](#outputs)
      - [Component-Specific Conventions](#component-specific-conventions)
      - [Enforcing Conventions](#enforcing-conventions)
    - [Reference and Validation](#reference-and-validation)
    - [Deferred Data Resource Patterns](#deferred-data-resource-patterns)
    - [File Organization Standards](#file-organization-standards)
      - [Main File Organization](#main-file-organization)
      - [Variables Organization](#variables-organization)
      - [Outputs Organization](#outputs-organization)

<!-- </table-of-contents> -->

## Terraform Coding Conventions

### Terraform General Conventions

<!-- <terraform-general-conventions> -->

#### File and Naming Standards

- You MUST use `kebab-case` for file/folder names, `snake_case` for resources/variables
- You MUST format code via `terraform fmt`
- You MUST NEVER use deprecated properties

#### Documentation and Comments

- You MUST use `//` for single-line or `/* */` for multi-line comments; NEVER use `#`
- You MUST include a markdown comment at the TOP of EVERY `main.tf` file
- You MUST provide descriptive `description` for all variables/outputs, ending with a period
- You MUST add meaningful and factual comments for non-obvious code
- You MUST NOT add redundant comments

#### Variables and Parameters

- You MUST specify `type` for all variables
- You MUST start boolean variables with `should_` or `is_`
- You MUST NOT add defaults to required variables
- You MUST include fallback values in descriptions (e.g., "Otherwise, 'id-{resource_prefix}-{environment}-{instance}'.")
- You MUST sort variables alphabetically within functional groupings
- You MUST use `try()`, `coalesce()` instead of ternary operators where possible
- You MUST provide variables for common settings
- You MUST use proper resource references for dependencies
- You MUST NOT use ternary operators unless unavoidable

#### Variable Description Standards

- You MUST NOT end variable descriptions with periods
- You MUST use standardized descriptions for common variables:
  - Environment: `Environment for all resources in this module: dev, test, or prod`
  - Location: `Location for all resources in this module`
  - Resource Prefix: `Prefix for all resources in this module`
  - Instance: `Instance identifier for naming resources: 001, 002, etc`
- You MUST use consistent Azure service terminology:
  - Use "User Assigned Managed Identity" (not variations like "User-Assigned" or "UAI")
  - Use "location" (not "region")
  - Use "resource group object containing name and id" for resource group variables
- You MUST include examples for constrained variables
- You MUST specify object properties for complex types
- You MUST add security warnings for development-only features

#### Module Structure

- You MUST NOT create provider blocks in component/internal modules
- You MUST NOT modify provider blocks except in `blueprints/`, `ci/`, or `tests/`
- You MUST NOT violate module relationship rules when referencing modules

#### Deferred Data Resources

- You MUST use `terraform_data` resources to defer data source computations when build systems lack permissions for `terraform plan`
- You MUST name deferred resources with `defer` prefix (e.g., `terraform_data.defer`, `terraform_data.defer_azuread_user`)
- You MUST include explanatory comment for deferred data resources explaining build system compatibility requirement
- You SHOULD use conditional counts on `terraform_data` deferred resources when the deferral is conditional
- You MUST reference deferred outputs using `.output` syntax (e.g., `terraform_data.defer.output.resource_group_name`)
- You MUST use `alltrue()`, `try()`, and `coalesce()` functions for complex conditional logic in deferred patterns
- You MUST use `try()`, and when needed `coalesce()` functions for references to `data` deferred resources

#### Resource Naming

- You MUST follow [Azure naming conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- You MUST use these patterns:
  - Hyphens allowed: `{resource_abbreviation}-${var.resource_prefix}-{optional_extra}-${var.environment}-${var.instance}`
  - Hyphens not allowed: `{resource_abbreviation}${var.resource_prefix}{optional_extra}${var.environment}${var.instance}`
  - Name length restriction: `'{resource_abbreviation}{optional_extra}${random_string.resource}'`
- **Map-based resources**: When using `for_each` with map variables, use `name = each.key` directly UNLESS variable documentation specifies otherwise

#### Outputs

- You MUST output resources as objects with necessary fields
- You MUST set `sensitive = true` for secrets
- You MUST provide meaningful and useful descriptions
- You MUST use functions like `try()` or `coalesce()`
- You MUST NOT use ternary operators if alternatives exist

#### Component-Specific Conventions

For Components ONLY:

- You MUST provide defaults for optional variables
- You MUST provide `validation` for variables where conditions are known
- You MUST place resources in `main.tf`
- You MUST NEVER reference another component directly
- You MUST receive existing resources as objects with only necessary fields

For Internal modules ONLY:

- You MUST NEVER provide defaults or validation for variables
- You MUST place resources in `{component_name}/terraform/modules/{module_name}/main.tf`
- You MUST NEVER use a component or another component's internal modules

#### Enforcing Conventions

You MUST ALWAYS ensure Terraform conventions are followed:

- CONTINUOUSLY evaluate if your changes adhere to these conventions
- Correct any deviations from these conventions
- Suggest convention updates if user changes conflict with conventions
<!-- </terraform-general-conventions> -->

### Reference and Validation

<!-- <reference-validation> -->

- You MUST search the codebase for existing Terraform resources before editing
- If no reference exists:

  1. Use HashiCorp Registry documentation
  2. Check for deprecated fields and use latest properties
  3. Verify provider version requirements
  4. Review common usage examples

- For `azapi` resources (use ONLY if no `azurerm` resource exists):
  1. Use Azure ARM template reference
  2. Extract resource type for `azapi` with latest API version
  3. Identify required properties for the `body` parameter
  4. Example:

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
        host = "${var.eventhub.namespace_name}.servicebus.windows.net:9093"
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

### Deferred Data Resource Patterns

You MUST use these patterns when build systems lack permissions to query specific Azure resources during `terraform plan`:

<!-- <deferred-patterns> -->

**Simple Resource Deferral** (CI environments):

```terraform
// Defer computation to prevent `data` objects from querying for state on `terraform plan`.
// Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "aio" {
  name = terraform_data.defer.output.resource_group_name
}
```

**Conditional Azure AD Deferral**:

```terraform
resource "terraform_data" "defer_azuread_user" {
  count = var.should_add_current_user_cluster_admin ? 1 : 0
  input = {
    object_id = data.azurerm_client_config.current.object_id
  }
}

data "azuread_user" "current" {
  count     = length(terraform_data.defer_azuread_user)
  object_id = terraform_data.defer_azuread_user[0].output.object_id
}
```
<!-- </deferred-patterns> -->

- After edits, you MUST:
  1. Run `terraform fmt` and `terraform validate`
  2. Verify VS Code's Terraform diagnostics
  3. Fix all validation issues before committing
  <!-- </reference-validation> -->

### File Organization Standards

This section details how to organize content within specific Terraform files.

#### Main File Organization

<!-- <component-main-tf-example> -->

All `main.tf` files MUST follow this organization:

1. Markdown `/** */` comment at the top with title and description
2. Local variables in one `locals` block, grouped by functionality
3. Deferred data resource computations using `terraform_data` (when required)
4. `data` resources, grouped by functionality
5. `resource` resources, grouped by functionality
6. `module` resources, grouped by functionality

Example:

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
}

// Defer computation to prevent `data` objects from querying for state on `terraform plan`.
// Needed for testing and build system compatibility.
data "azurerm_client_config" "current" {}

resource "terraform_data" "defer_azuread_user" {
  count = var.should_add_current_user_cluster_admin ? 1 : 0
  input = {
    object_id = data.azurerm_client_config.current.object_id
  }
}

data "azuread_user" "current" {
  count     = length(terraform_data.defer_azuread_user)
  object_id = terraform_data.defer_azuread_user[0].output.object_id
}

resource "terraform_data" "defer_custom_locations" {
  count = alltrue([var.should_get_custom_locations_oid, try(length(var.custom_locations_oid), 0) == 0]) ? 1 : 0
  input = {
    // ref: https://learn.microsoft.com/azure/iot-operations/deploy-iot-ops/howto-prepare-cluster?tabs=ubuntu#arc-enable-your-cluster
    client_id = "bc313c14-388c-4e7d-a58e-70017303ee3b" #gitleaks:allow
  }
}

data "azuread_service_principal" "custom_locations" {
  count     = length(terraform_data.defer_custom_locations)
  client_id = terraform_data.defer_custom_locations[0].output.client_id
}

resource "azurerm_role_assignment" "connected_machine_onboarding" {
  count = var.should_assign_roles ? 1 : 0

  principal_id         = try(var.arc_onboarding_identity.principal_id, var.arc_onboarding_sp.object_id)
  role_definition_name = "Kubernetes Cluster - Azure Arc Onboarding"
  scope                = var.resource_group.id
}

module "ubuntu_k3s" {
  source = "./modules/ubuntu-k3s"

  aio_resource_group  = var.resource_group
  arc_onboarding_sp   = var.arc_onboarding_sp
  arc_resource_name   = local.arc_resource_name
  // Additional parameters omitted for brevity
}
```

<!-- </component-main-tf-example> -->

#### Variables Organization

<!-- <component-variables-tf-example> -->

All variables files MUST follow this organization:

1. Required variables (no defaults) grouped at the top
2. Optional variables grouped by functionality
3. Each group with clear comment header
4. Variables alphabetically sorted within groups

Example:

```terraform
/*
 *  Azure Arc Parameters - Required
 */

variable "should_get_custom_locations_oid" {
  type        = bool
  description = "Whether to get Custom Locations Object ID using Terraform's azuread provider."
}

/*
 * File System Parameters - Optional
 */

variable "script_output_filepath" {
  type        = string
  description = "The location of where to write out the script file. (Otherwise, '{path.root}/out')."
  default     = null
}

/*
 *  Azure Arc Parameters - Optional
 */

variable "custom_locations_oid" {
  type        = string
  description = "The object id of the Custom Locations Entra ID application for your tenant."
  default     = null
}
```

<!-- </component-variables-tf-example> -->

#### Outputs Organization

<!-- <outputs-tf-example> -->

All `outputs.tf` files MUST follow this organization:

1. Outputs grouped by functionality with clear comment headers
2. Outputs sorted alphabetically within each group
3. Consistent field order: `description`, `value`, `sensitive` (if applicable)

Example:

```terraform
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
 * Arc Connected Cluster Outputs
 */

output "azure_arc_proxy_command" {
  description = "The AZ CLI command to proxy to the Arc Connected cluster."
  value       = "az connectedk8s proxy -n ${local.arc_resource_name} -g ${var.resource_group.name}"
}
```

<!-- </outputs-tf-example> -->
