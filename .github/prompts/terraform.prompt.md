---
mode: 'agent'
tools: ['terminalLastCommand', 'terminalSelection', 'codebase', 'fetch', 'problems', 'searchResults', 'usages', 'vscodeAPI']
description: 'Provides Prompt Instructions for Terraform IaC'
---
# Terraform Instructions

You are an expert in Terraform Infrastructure as Code (IaC) with deep knowledge of Azure resources provided by the `azurerm`, `azapi`, and `azuread` providers. When writing or evaluating Terraform code, always follow the conventions in this document.

## Repository Structure

This repository is organized with the following key directories:

1. **Source Components** (`src/`) - Individual reusable infrastructure components:
   - `000-cloud/` - Cloud-based resources (Storage, Identity, Observability, etc.)
   - `100-edge/` - Edge-based resources (IoT Operations, CNCF clusters, etc.)
   - `500-application/` - Application resources and source code
   - `900-tools-utilities/` - Tools and utilities (YAML, Helm charts, etc.)

2. **Blueprints** (`blueprints/`) - End-to-end solutions that combine components:
   - `full-single-node-cluster/` - Single-node AIO deployment
   - `full-multi-node-cluster/` - Multi-node HA AIO deployment
   - `only-output-cncf-cluster-script/` - Script-only deployment

## Module Types: Component Modules vs. Internal Modules

### Component Modules

Component Modules are the top-level, standalone modules that provide a specific capability or resource set within the repository. They are located under `src/000-grouping/000-component/terraform`, where `000-grouping` is the meta grouping (like `cloud` or `edge`), and `000-component` is the Component Module.

**Characteristics of Component Modules:**

- Located directly under a component directory in `src/` (e.g., `src/000-cloud/010-security-identity/terraform/`)
- Exposed to be called from **Blueprint** modules
- Represent a complete, self-contained functional unit (e.g., VM Host, CNCF Cluster, IoT Ops)
- Can use their own Internal Modules but NEVER reference other Component Modules
- Usually deployed in a specific order based on their directory naming
- Have comprehensive documentation and tests in a `tests` directory
- May include a corresponding `ci/terraform` directory for CI/CD pipeline integration

**Example Component Module path:**

```plain
src/000-cloud/030-data/terraform/
```

### Internal Modules

Internal Modules are subordinate, reusable modules that are only used within their parent Component Module. They help organize and modularize the Component Module's implementation.

**Characteristics of Internal Modules:**

- Located in the `modules` subdirectory of a Component Module (e.g., `src/000-cloud/030-data/terraform/modules/storage-account/`)
- NEVER called directly from Blueprints or other Component Modules
- Only called from their parent Component Module
- Implement specific functionality within the scope of their parent Component
- Have narrower scope and focused responsibility
- No tests directory (tests are at the Component Module level)
- NEVER include default values for variables

**Example Internal Module path:**

```plain
src/000-cloud/030-data/terraform/modules/storage-account/
```

### CI Terraform Directories

CI Terraform directories are wrapper directories used for CI/CD integration that leverage Component Modules:

**Characteristics of CI Terraform Directories:**

- Located at `<component>/ci/terraform/` (e.g., `src/000-cloud/030-data/ci/terraform/`)
- Contains simple code that calls the parent Component Module with default/test configurations
- Used for individual component testing and verification in CI/CD pipelines
- May include additional configuration specific to CI/CD integration

## Component Structure

Each component follows a decimal naming convention for deployment order (e.g., `000-resource-group`, `010-security-identity`):

```plain
src/
  000-cloud/
    010-security-identity/
      terraform/          # This is a COMPONENT MODULE
        main.tf
        variables.tf
        variables.core.tf
        variables.deps.tf
        outputs.tf
        versions.tf
        modules/
          key-vault/      # This is an INTERNAL MODULE
            main.tf
            variables.tf
            outputs.tf
      ci/
        terraform/        # This is a CI TERRAFORM DIRECTORY
          main.tf
          variables.tf
          versions.tf
```

### Component Files Organization

ALWAYS use consistent file organization:

1. `main.tf` - Primary resource definitions
2. `variables.tf` - Optional variables with defaults
3. `variables.core.tf` - Required core variables (strings, numbers, etc.)
4. `variables.deps.tf` - Required dependency variables (objects for resources created from other modules)
5. `variables.<module>.tf` - (Optional) Module-specific variables
6. `outputs.tf` - Module outputs
7. `versions.tf` - Provider requirements

## Blueprint Structure

Blueprints compose multiple source components into complete solutions:

```plain
blueprints/
  full-single-node-cluster/
    terraform/            # This is a BLUEPRINT MODULE
      main.tf             # Calls multiple COMPONENT MODULES but NEVER INTERNAL MODULES
      variables.tf
      outputs.tf
      versions.tf
    README.md
```

Each blueprint includes:

- `main.tf` - Main orchestration calling source components
- `variables.tf` - Variables for the blueprint
- `outputs.tf` - Important resource information
- `versions.tf` - Provider configuration
- `README.md` - Deployment instructions

## Terraform Coding Conventions

### General Conventions

- ALWAYS use `kebab-case` for file and folder names
- ALWAYS use `snake_case` for resource names and variables
- ALWAYS format code according to Terraform standards (`terraform fmt`)
- NEVER use deprecated properties on Terraform resources
- NEVER use the `#` symbol for comments, use `//` for single-line or `/* */` for multi-line comments
- ALWAYS include a markdown-formatted comment at the TOP of EVERY `main.tf` file

### Resource Structure

Resources should follow this order:

1. Count/for_each (if applicable)
2. Resource-specific required parameters
3. Common parameters (name, location, etc.)
4. Dependencies
5. Tags
6. Other parameters

Example:

```hcl
/**
 * # Example Component
 *
 * Creates example resources needed for this component.
 * Provides detailed information about what will be deployed.
 */

// Locals at the TOP after the module description
locals {
  // Using functions like try() and coalesce() instead of ternary operators
  custom_locations_oid = try(coalesce(var.custom_locations_oid, data.azuread_service_principal.custom_locations[0].object_id), "")
}

// Data resources AFTER locals
data "azurerm_client_config" "current" {}

// Resources AFTER data sources
resource "azurerm_monitor_workspace" "monitor" {
  name                = "azmon-${var.resource_prefix}-${var.environment}-${var.instance}"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
}

// Modules LAST
module "example_internal_module" {
  count = var.should_create_example ? 1 : 0

  // source comes AFTER count
  source = "./modules/example-internal-module"

  // depends_on comes AFTER source
  depends_on = [azurerm_monitor_workspace.monitor]

  // Variables grouped and sorted
  resource_group      = var.resource_group
  environment         = var.environment
  instance            = var.instance
  location            = var.location
  resource_prefix     = var.resource_prefix
}
```

### Module and Component Relationships

IMPORTANT RULES:

- Component Modules (e.g., `src/000-cloud/010-security-identity/terraform/`) NEVER reference other Component Modules
- Component Modules NEVER reference other Component Modules' Internal Modules
- Component Modules ONLY reference their own Internal Modules
- Internal Modules (e.g., `src/000-cloud/010-security-identity/terraform/modules/key-vault/`) NEVER reference other Component Modules
- Internal Modules NEVER reference other Component Modules' Internal Modules
- Internal Modules NEVER reference other Internal Modules
- Blueprint Modules (e.g., `blueprints/full-single-node-cluster/terraform/`) ONLY reference Component Modules, NEVER Internal Modules

### Variables Conventions

1. Group variables with clear section comments:

```hcl
/*
 * Resource Group - Required
 */

variable "resource_group" {
  description = "Resource group for all resources in this module."
  type        = object({
    name     = string
    id       = optional(string)
    location = optional(string)
  })
}

/*
 * Core Settings - Required
 */

variable "environment" {
  description = "Environment for all resources in this module: dev, test, or prod."
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for all resources in this module."
  type        = string
}

/*
 * Storage Settings - Optional
 */

variable "storage_account_tier" {
  description = "Defines the Tier to use for this storage account (Standard or Premium)."
  type        = string
  default     = "Standard"
}
```

- Follow these guidelines:
  - ALWAYS provide descriptive `description` that ends with a period
  - ALWAYS specify `type` for all variables
  - Boolean variables SHOULD start with `should_` or `is_`
  - Required variables SHOULD NOT have defaults
  - Include fallback values in descriptions: "Otherwise, 'id-{resource_prefix}-{environment}-{instance}'"
  - Variables SHOULD be sorted alphabetically within each grouping

- For Internal Modules:
  - NEVER include `default` values
  - NEVER include `validation` blocks
  - These should be defined in the parent Component Module

### Outputs Conventions

- ALWAYS return objects for resources that can be dependencies
- ALWAYS set `sensitive = true` for secrets
- ALWAYS provide helpful descriptions
- ALWAYS use functions like `try()` instead of ternary operators
- Follow consistent ordering: `description`, `sensitive` (if needed), `value`

Example:

```hcl
output "key_vault" {
  description = "The newly created Key Vault."
  value = try({
    id   = module.key_vault[0].key_vault.id
    name = module.key_vault[0].key_vault.name
  }, null)
}
```

### Resource Naming Conventions

- ALWAYS use Azure resource naming conventions
- ALWAYS follow this pattern: `<resource-abbreviation>-${var.resource_prefix}-${var.environment}-${var.instance}`
- Examples:
  - `kv-${var.resource_prefix}-${var.environment}-${var.instance}` for Key Vault
  - `st${var.resource_prefix}${var.environment}${var.instance}` for Storage Account
  - `arck-${var.resource_prefix}-${var.environment}-${var.instance}` for Arc Kubernetes

### Testing

- Always include tests in a `tests` directory of the component module
- Test both default configurations and custom configurations
- Use assertions to verify critical attributes and resource creation

## Terraform DOs and DON'Ts

### DO

- DO use `try()`, `coalesce()`, and other Terraform functions instead of ternary operators
- DO provide variables for common settings
- DO use accurate abbreviations for resource types in naming conventions
- DO add helpful comments that clarify non-obvious code (e.g., references to docs)
- DO include all required parameters and validate them
- DO use proper resource references to establish dependencies

### DON'T

- DON'T use deprecated properties on Terraform resources
- DON'T use ternary operators (`? :`), unless there is no other option such as `for_each = var.arc_onboarding_identity_id != null ? [1] : []`
- DON'T add useless comments that just describe what the code already clearly shows
- DON'T create provider blocks in component or internal modules
- DON'T modify provider blocks except in `blueprints/`, `ci/`, or `tests/` directories
- DON'T reference modules in ways that violate the module relationship rules

## Pre-Implementation Checklist

Before making ANY changes to Terraform code, ask yourself:

- [ ] Am I working on a Component Module, an Internal Module, or a Blueprint?
  - Component Module: Located directly under `src/000-grouping/000-component/terraform/`
  - Internal Module: Located under `src/000-grouping/000-component/terraform/modules/module-name/`
  - Blueprint: Located under `blueprints/blueprint-name/terraform/`
- [ ] Am I following the correct file structure for this module type?
- [ ] Will my module references follow the module relationship rules?
- [ ] Are my variables organized in the appropriate files?
- [ ] Does my module use the correct naming conventions?

## Post-Implementation Checklist

After completing ALL changes, verify:

- [ ] Are module references correct and following relationship rules?
- [ ] Are variables properly organized and sorted?
- [ ] Are outputs properly organized and returning dependency objects?
- [ ] Is the resource ordering correct in `main.tf`?
- [ ] Are all variables properly typed and described?
- [ ] Are there any ternary operators that should be replaced?
- [ ] Are resource names following conventions?
- [ ] Is the code properly formatted (`terraform fmt`)?
- [ ] Are there any deprecated resources, properties, or functions?
- [ ] Do all files have appropriate comments?
- [ ] Have all tests been updated and are passing?
