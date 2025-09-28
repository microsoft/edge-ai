# Terraform Instructions

You are an expert in Terraform Infrastructure as Code (IaC) with deep knowledge of Azure resources.

* You MUST reference [Terraform Standards](terraform-standards.md) for detailed coding standards and conventions.
* You MUST ALWAYS meticulously follow these Terraform standards and conventions without deviation.
* Use the mcp_terraform tools to get the latest document to correctly implement Terraform.

## Terraform Project Structure

### Terraform Component Structure

<!-- <example-terraform-component-structure> -->
```plain
src/
  000-cloud/
    010-security-identity/
      terraform/          # COMPONENT MODULE
        main.tf           # Main orchestration
        variables.tf      # Component/internal module variables
        variables.core.tf # Core variables (consistent across components)
        variables.deps.tf # Inter-component dependencies (Optional)
        outputs.tf        # Component/internal module outputs
        versions.tf       # Provider requirements
        modules/
          key-vault/      # INTERNAL MODULE
            main.tf
            variables.tf  # Internal module variables (no defaults)
            outputs.tf    # Outputs for component use
            versions.tf   # Provider requirements (consistent)
      ci/
        terraform/        # CI TERRAFORM DIRECTORY
          main.tf         # CI deployment wrapper
          variables.tf    # Minimum required variables for CI
          versions.tf     # Includes provider "azurerm" block
```
<!-- </example-terraform-component-structure> -->

### Terraform Component Files Organization

<!-- <component-files-organization> -->
You MUST use this file organization for all components:

1. `main.tf` - Primary resource definitions and orchestration
2. `variables.tf` - Component/internal module variables with defaults
3. `variables.core.tf` - Core variables consistent across components
4. `variables.deps.tf` - (Optional) Dependencies from other components as objects
5. `variables.<module>.tf` - (Optional) Module-specific variables
6. `outputs.tf` - Outputs for use by other components/modules
7. `versions.tf` - Required Terraform providers
<!-- </component-files-organization> -->

### Terraform CI Directories

<!-- <example-terraform-ci> -->
```terraform
// ci/terraform/main.tf
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

// ci/terraform/variables.tf (excerpt)
variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod."
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module."
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z][-a-zA-Z0-9]*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes, and must start with an alphabetic character."
  }
}

// ci/terraform/versions.tf (excerpt)
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.8.0"
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

### Terraform Blueprint Structure

<!-- <example-terraform-blueprint-structure> -->
```plain
blueprints/
  full-single-node-cluster/
    terraform/            # BLUEPRINT MODULE
      main.tf             # Calls COMPONENT MODULES (NEVER INTERNAL MODULES)
      variables.tf        # Variables for locals or component inputs
      outputs.tf          # Outputs from constituent components
      versions.tf         # Includes provider "azurerm" block
    README.md             # Essential deployment instructions
```
<!-- </example-terraform-blueprint-structure> -->
