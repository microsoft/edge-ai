<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Container Registry (ACR)

Deploys Azure Container Registry resources

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm | >= 4.8.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| container\_registry | ./modules/container-registry | n/a |
| network | ./modules/network | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| network\_security\_group | n/a | ```object({ id = string })``` | n/a | yes |
| resource\_group | Resource group object containing name and id where resources will be deployed | ```object({ name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| virtual\_network | n/a | ```object({ name = string id = string })``` | n/a | yes |
| allow\_trusted\_services | Whether trusted Azure services can bypass registry network rules when the public endpoint is restricted | `bool` | `true` | no |
| allowed\_public\_ip\_ranges | CIDR ranges permitted to reach the registry public endpoint | `list(string)` | `[]` | no |
| default\_outbound\_access\_enabled | Whether to enable default outbound internet access for the ACR subnet | `bool` | `false` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| nat\_gateway | NAT gateway object from the networking component for managed outbound access | ```object({ id = string name = string })``` | `null` | no |
| public\_network\_access\_enabled | Whether to enable the registry public endpoint alongside private connectivity | `bool` | `false` | no |
| should\_create\_acr\_private\_endpoint | Whether to create a private endpoint for the Azure Container Registry (default false) | `bool` | `false` | no |
| should\_enable\_data\_endpoints | Whether to enable dedicated data endpoints for the registry | `bool` | `true` | no |
| sku | SKU name for the resource | `string` | `"Premium"` | no |
| subnet\_address\_prefixes\_acr | Address prefixes for the ACR subnet | `list(string)` | ```[ "10.0.3.0/24" ]``` | no |

## Outputs

| Name | Description |
|------|-------------|
| acr | The Azure Container Registry resource created by this module, including network posture metadata. |
| acr\_network\_posture | Network posture for the Azure Container Registry, including public endpoint status, allow list, trusted services, and data endpoints. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
