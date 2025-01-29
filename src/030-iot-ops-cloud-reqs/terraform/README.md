<!-- BEGIN_TF_DOCS -->
# Azure IoT Operations Cloud Requirements

Sets up required cloud resources for Azure IoT Operations installation
including: Schema Registry, Azure Key Vault, and Roles and Permissions for
access to resources.

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

- azapi (>= 2.1.0)

- azuread (>= 3.0.2)

- azurerm (>= 4.8.0)

## Providers

The following providers are used by this module:

- azurerm (>= 4.8.0)

- terraform

## Resources

The following resources are used by this module:

- [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)
- [azurerm_resource_group.aio_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) (data source)

## Modules

The following Modules are called:

### schema\_registry

Source: ./modules/schema-registry

Version:

### sse\_key\_vault

Source: ./modules/sse-key-vault

Version:

### uami

Source: ./modules/uami

Version:

## Required Inputs

The following input variables are required:

### environment

Description: Environment for all resources in this module: dev, test, or prod

Type: `string`

### location

Description: Location for all resources in this module

Type: `string`

### resource\_prefix

Description: Prefix for all resources in this module

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### existing\_key\_vault\_name

Description: Name of the Azure Key Vault to use by Secret Sync Extension. If not provided, will create new key vault. Will fail if provided key vault does not exist in provided resource group.

Type: `string`

Default: `null`

### instance

Description: Instance identifier for naming resources: 001, 002, etc...

Type: `string`

Default: `"001"`

### resource\_group\_name

Description: The name for the resource group. (Otherwise, 'rg-{var.resource\_prefix}-{var.environment}-{var.instance}')

Type: `string`

Default: `null`

## Outputs

The following outputs are exported:

### aio\_uami\_name

Description: n/a

### schema\_registry\_id

Description: n/a

### sse\_key\_vault\_name

Description: n/a

### sse\_uami\_name

Description: n/a
<!-- END_TF_DOCS -->
