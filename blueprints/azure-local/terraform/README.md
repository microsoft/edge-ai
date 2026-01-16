<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Local IoT Operations Blueprint

Deploys the cloud and edge resources required to run Azure IoT Operations on an Azure Arc-enabled Azure Local device.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.51.0 |

## Providers

| Name | Version |
|------|---------|
| terraform | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Modules

| Name | Source | Version |
|------|--------|---------|
| arc\_cluster\_resource\_group | ../../../src/000-cloud/000-resource-group/terraform | n/a |
| azure\_local\_host | ../../../src/000-cloud/072-azure-local-host/terraform | n/a |
| cloud\_data | ../../../src/000-cloud/030-data/terraform | n/a |
| cloud\_messaging | ../../../src/000-cloud/040-messaging/terraform | n/a |
| cloud\_observability | ../../../src/000-cloud/020-observability/terraform | n/a |
| cloud\_resource\_group | ../../../src/000-cloud/000-resource-group/terraform | n/a |
| cloud\_security\_identity | ../../../src/000-cloud/010-security-identity/terraform | n/a |
| edge\_arc\_extensions | ../../../src/100-edge/109-arc-extensions/terraform | n/a |
| edge\_assets | ../../../src/100-edge/111-assets/terraform | n/a |
| edge\_iot\_ops | ../../../src/100-edge/110-iot-ops/terraform | n/a |
| edge\_messaging | ../../../src/100-edge/130-messaging/terraform | n/a |
| edge\_observability | ../../../src/100-edge/120-observability/terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| aio\_features | AIO features with mode ('Stable', 'Preview', 'Disabled') and settings ('Enabled', 'Disabled') | ```map(object({ mode = optional(string) settings = optional(map(string)) }))``` | `null` | no |
| arc\_cluster\_resource\_group\_name | Name of the resource group for Arc-connected cluster resources. Otherwise, will use the cloud resource group | `string` | `null` | no |
| asset\_endpoint\_profiles | List of asset endpoint profiles to create; otherwise, an empty list | ```list(object({ name = string target_address = string endpoint_profile_type = optional(string) method = optional(string) should_enable_opc_asset_discovery = optional(bool) opc_additional_config_string = optional(string) }))``` | `[]` | no |
| assets | List of assets to create; otherwise, an empty list | ```list(object({ asset_endpoint_profile_ref = string datasets = optional(list(object({ data_points = list(object({ data_point_configuration = optional(string) data_source = string name = string observability_mode = optional(string) })) name = string })), []) default_datasets_configuration = optional(string) description = optional(string) display_name = optional(string) documentation_uri = optional(string) enabled = optional(bool) hardware_revision = optional(string) manufacturer = optional(string) manufacturer_uri = optional(string) model = optional(string) name = string product_code = optional(string) serial_number = optional(string) software_revision = optional(string) }))``` | `[]` | no |
| azure\_local\_aad\_profile | Azure Active Directory profile configuration for the Azure Local Kubernetes cluster | ```object({ admin_group_object_ids = optional(list(string), []) enable_azure_rbac = bool tenant_id = optional(string) })``` | ```{ "admin_group_object_ids": [], "enable_azure_rbac": true, "tenant_id": null }``` | no |
| azure\_local\_control\_plane\_count | Number of control plane nodes for Azure Local cluster | `number` | `1` | no |
| azure\_local\_control\_plane\_vm\_size | VM size for control plane nodes in Azure Local cluster | `string` | `"Standard_A4_v2"` | no |
| azure\_local\_node\_pool\_count | Number of worker nodes in the default node pool for Azure Local cluster | `number` | `1` | no |
| azure\_local\_node\_pool\_vm\_size | VM size for worker nodes in Azure Local cluster | `string` | `"Standard_D8s_v3"` | no |
| azure\_local\_pod\_cidr | CIDR range for Kubernetes pods in Azure Local cluster | `string` | `"10.244.0.0/16"` | no |
| custom\_locations\_oid | Resource ID of the custom location for the Azure Stack HCI cluster | `string` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| logical\_network\_name | Name of the logical network for the Azure Local Kubernetes cluster | `string` | `null` | no |
| logical\_network\_resource\_group\_name | Name of the resource group containing the logical network for the Azure Local Kubernetes cluster | `string` | `null` | no |
| resource\_group\_name | Name of the resource group to create or use. Otherwise, 'rg-{resource\_prefix}-{environment}-{instance}' | `string` | `null` | no |
| should\_create\_anonymous\_broker\_listener | Whether to enable an insecure anonymous AIO MQ broker listener; use only for dev or test environments | `bool` | `false` | no |
| should\_create\_azure\_functions | Whether to create Azure Functions resources for downstream messaging integrations | `bool` | `false` | no |
| should\_create\_data\_lake | Whether to create a Data Lake Gen2 storage account instead of a standard storage account | `bool` | `true` | no |
| should\_deploy\_resource\_sync\_rules | Whether to deploy resource sync rules | `bool` | `true` | no |
| should\_enable\_key\_vault\_public\_network\_access | Whether to enable public network access for the Key Vault | `bool` | `true` | no |
| should\_enable\_opc\_ua\_simulator | Whether to deploy the OPC UA simulator to the cluster | `bool` | `false` | no |
| should\_enable\_storage\_public\_network\_access | Whether to enable public network access for the storage account | `bool` | `true` | no |
| storage\_account\_is\_hns\_enabled | Whether to enable hierarchical namespace on the storage account | `bool` | `true` | no |
| use\_existing\_resource\_group\_for\_arc\_cluster | Whether to use an existing resource group for Arc-connected cluster resources with the provided or computed name instead of creating a new one | `bool` | `true` | no |
| use\_existing\_resource\_group\_for\_cloud | Whether to use an existing resource group for cloud resources with the provided or computed name instead of creating a new one | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| arc\_connected\_cluster | Arc connected cluster resource object |
| assets | Azure IoT Operations asset definitions |
| azure\_iot\_operations | Azure IoT Operations deployment details |
| cluster\_connection | Commands and identifiers for Arc connected cluster |
| messaging | Messaging resources for cloud to edge connectivity |
| observability | Observability resources |
| resource\_group | Resource group used for the blueprint |
| storage | Storage account information |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
