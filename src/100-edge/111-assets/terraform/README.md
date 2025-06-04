<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Kubernetes Assets

Deploys Kubernetes asset definitions to a connected cluster. This component
facilitates the management of custom Kubernetes resources and manifests.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 1.8.0 |
| azuread | >= 2.0.0 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| azapi | >= 1.8.0 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.asset](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.asset_endpoint_profile](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |

## Modules

| Name | Source | Version |
|------|--------|---------|
| k8\_bridge\_role\_assignment | ./modules/role-assignment-post | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| custom\_location\_id | The ID (resource ID) of the custom location to retrieve. | `string` | n/a | yes |
| location | Azure region where resources will be deployed. | `string` | n/a | yes |
| resource\_group | Resource group object containing name and id where resources will be deployed. | ```object({ name = string id = string })``` | n/a | yes |
| asset\_endpoint\_profiles | List of asset endpoint profiles to create. Otherwise, an empty list. | ```list(object({ endpoint_profile_type = optional(string) method = optional(string) name = string opc_sim_additional_config_string = optional(string) should_enable_opc_asset_discovery = optional(bool) target_address = string }))``` | `[]` | no |
| assets | List of assets to create. Otherwise, an empty list. | ```list(object({ asset_endpoint_profile_ref = string datasets = optional(list(object({ data_points = list(object({ data_point_configuration = optional(string) data_source = string name = string observability_mode = optional(string) })) name = string })), []) default_datasets_configuration = optional(string) description = optional(string) display_name = optional(string) documentation_uri = optional(string) enabled = optional(bool) hardware_revision = optional(string) manufacturer = optional(string) manufacturer_uri = optional(string) model = optional(string) name = string product_code = optional(string) serial_number = optional(string) software_revision = optional(string) }))``` | `[]` | no |
| k8s\_bridge\_principal\_id | Optional. The principal ID of the K8 Bridge for Azure IoT Operations. Required only if enable\_asset\_discovery=true and automatic retrieval fails. If null and enable\_asset\_discovery=true, will be automatically retrieved using the service principal data source.  Can be retrieved manually using: ```sh az ad sp list --display-name "K8 Bridge" --query "[0].appId" -o tsv``` | `string` | `null` | no |
| should\_create\_default\_asset | Whether to create a default asset. Otherwise, false. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| asset\_endpoint\_profiles | Map of asset endpoint profiles created by this component. |
| assets | Map of assets created by this component. |
| should\_enable\_opc\_asset\_discovery | Whether OPC simulation asset discovery is enabled for any endpoint profile. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
