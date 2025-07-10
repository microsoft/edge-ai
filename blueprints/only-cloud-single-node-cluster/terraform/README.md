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
| azurerm | >= 4.8.0 |

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
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| resource\_group\_name | The name for the resource group. If not provided, a default name will be generated using resource\_prefix, environment, and instance. | `string` | `null` | no |
| should\_create\_acr\_private\_endpoint | Should create a private endpoint for the Azure Container Registry. Default is false. | `bool` | `false` | no |
| should\_create\_aks | Should create Azure Kubernetes Service. Default is false. | `bool` | `false` | no |
| should\_create\_azure\_functions | Whether to create Azure Functions for the cluster | `bool` | `false` | no |
| use\_existing\_resource\_group | Whether to use an existing resource group instead of creating a new one. When true, the component will look up a resource group with the specified or generated name instead of creating it. | `bool` | `false` | no |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
