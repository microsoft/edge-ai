<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Full Cloud Single Node Cluster Blueprint

This blueprint deploys a complete end-to-end cloud environment as preparation for Azure IoT Operations on a single-node.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.51.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| cloud\_acr | ../../../src/000-cloud/060-acr/terraform | n/a |
| cloud\_data | ../../../src/000-cloud/030-data/terraform | n/a |
| cloud\_kubernetes | ../../../src/000-cloud/070-kubernetes/terraform | n/a |
| cloud\_messaging | ../../../src/000-cloud/040-messaging/terraform | n/a |
| cloud\_networking | ../../../src/000-cloud/050-networking/terraform | n/a |
| cloud\_observability | ../../../src/000-cloud/020-observability/terraform | n/a |
| cloud\_resource\_group | ../../../src/000-cloud/000-resource-group/terraform | n/a |
| cloud\_security\_identity | ../../../src/000-cloud/010-security-identity/terraform | n/a |
| cloud\_vm\_host | ../../../src/000-cloud/051-vm-host/terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| dns\_prefix | DNS prefix for the AKS cluster. This is used to create a unique DNS name for the cluster. If not provided, a default value will be generated. | `string` | `null` | no |
| enable\_auto\_scaling | Should enable auto-scaler for the default node pool. | `bool` | `false` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| max\_count | The maximum number of nodes which should exist in the default node pool. Valid values are between 0 and 1000. | `number` | `null` | no |
| min\_count | The minimum number of nodes which should exist in the default node pool. Valid values are between 0 and 1000. | `number` | `null` | no |
| nat\_gateway\_idle\_timeout\_minutes | Idle timeout in minutes for NAT gateway connections | `number` | `4` | no |
| nat\_gateway\_public\_ip\_count | Number of public IP addresses to associate with the NAT gateway (example: 2) | `number` | `1` | no |
| nat\_gateway\_zones | Availability zones for NAT gateway resources when zone-redundancy is required (example: ['1','2']) | `list(string)` | `[]` | no |
| node\_count | Number of nodes for the agent pool in the AKS cluster. | `number` | `1` | no |
| node\_pools | Additional node pools for the AKS cluster. Map key is used as the node pool name. | ```map(object({ node_count = number vm_size = string subnet_address_prefixes = list(string) pod_subnet_address_prefixes = list(string) node_taints = optional(list(string), []) enable_auto_scaling = optional(bool, false) min_count = optional(number, null) max_count = optional(number, null) }))``` | `{}` | no |
| node\_vm\_size | VM size for the agent pool in the AKS cluster. Default is Standard\_D8ds\_v5. | `string` | `"Standard_D8ds_v5"` | no |
| resource\_group\_name | Name of the resource group | `string` | `null` | no |
| should\_create\_aks | Should create Azure Kubernetes Service. Default is false. | `bool` | `false` | no |
| should\_create\_azure\_functions | Whether to create the Azure Functions resources including App Service Plan | `bool` | `false` | no |
| should\_enable\_managed\_outbound\_access | Whether to enable managed outbound egress via NAT gateway instead of platform default internet access | `bool` | `true` | no |
| should\_enable\_private\_endpoints | Whether to enable private endpoints for Key Vault and Storage Account | `bool` | `false` | no |
| subnet\_address\_prefixes\_aks | Address prefixes for the AKS subnet. | `list(string)` | ```[ "10.0.4.0/24" ]``` | no |
| subnet\_address\_prefixes\_aks\_pod | Address prefixes for the AKS pod subnet. | `list(string)` | ```[ "10.0.5.0/24" ]``` | no |
| use\_existing\_resource\_group | Whether to use an existing resource group instead of creating a new one. When true, the component will look up a resource group with the specified or generated name instead of creating it. | `bool` | `false` | no |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
