<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure IoT Operations Cloud Requirements

Sets up required cloud resources for Azure IoT Operations installation
including: Schema Registry, Azure Key Vault, and Roles and Permissions for
access to resources.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.2.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.8.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| schema\_registry | ./modules/schema-registry | n/a |
| sse\_key\_vault | ./modules/sse-key-vault | n/a |
| uami | ./modules/uami | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_resource\_group | n/a | ```object({ name = string location = string })``` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| sse\_key\_vault | Azure Key Vault ID to use with Secret Sync Extension. | ```object({ id = string })``` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| adr\_schema\_registry | n/a |
| aio\_uami\_name | n/a |
| aio\_user\_assigned\_identity | n/a |
| schema\_registry\_id | n/a |
| sse\_key\_vault | n/a |
| sse\_key\_vault\_name | n/a |
| sse\_uami\_name | n/a |
| sse\_user\_assigned\_identity | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
