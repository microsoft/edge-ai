<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Full Arc Server Multi Node Cluster Blueprint

Deploys a full deployment with (almost) all components onto Arc enabled Servers.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.8.0 |
| terraform | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [azurerm_arc_machine.machines](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/arc_machine) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| cloud\_data | ../../../src/000-cloud/030-data/terraform | n/a |
| cloud\_messaging | ../../../src/000-cloud/040-messaging/terraform | n/a |
| cloud\_observability | ../../../src/000-cloud/020-observability/terraform | n/a |
| cloud\_resource\_group | ../../../src/000-cloud/000-resource-group/terraform | n/a |
| cloud\_security\_identity | ../../../src/000-cloud/010-security-identity/terraform | n/a |
| edge\_assets | ../../../src/100-edge/111-assets/terraform | n/a |
| edge\_cncf\_cluster | ../../../src/100-edge/100-cncf-cluster/terraform | n/a |
| edge\_iot\_ops | ../../../src/100-edge/110-iot-ops/terraform | n/a |
| edge\_messaging | ../../../src/100-edge/130-messaging/terraform | n/a |
| edge\_observability | ../../../src/100-edge/120-observability/terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: e.g., dev, test, prod, etc. | `string` | n/a | yes |
| location | Location for all resources in this module. | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module. | `string` | n/a | yes |
| arc\_machine\_count | The number of arc machines that will be in the cluster. | `number` | `2` | no |
| arc\_machine\_name\_prefix | The prefix for the arc machine names. | `string` | `null` | no |
| arc\_machine\_resource\_group\_name | The name of the Resource Group for the arc machines. | `string` | `null` | no |
| asset\_endpoint\_profiles | List of asset endpoint profiles to create. Otherwise, an empty list. | ```list(object({ name = string target_address = string endpoint_profile_type = optional(string) method = optional(string) should_enable_opc_asset_discovery = optional(bool) opc_additional_config_string = optional(string) }))``` | `[]` | no |
| assets | List of assets to create. Otherwise, an empty list. | ```list(object({ asset_endpoint_profile_ref = string datasets = optional(list(object({ data_points = list(object({ data_point_configuration = optional(string) data_source = string name = string observability_mode = optional(string) })) name = string })), []) default_datasets_configuration = optional(string) description = optional(string) display_name = optional(string) documentation_uri = optional(string) enabled = optional(bool) hardware_revision = optional(string) manufacturer = optional(string) manufacturer_uri = optional(string) model = optional(string) name = string product_code = optional(string) serial_number = optional(string) software_revision = optional(string) }))``` | `[]` | no |
| cluster\_server\_host\_machine\_username | The username for the cluster server that will be given kubectl access. | `string` | `null` | no |
| cluster\_server\_ip | The IP Address for the cluster server that the cluster nodes will use to connect. | `string` | `null` | no |
| custom\_locations\_oid | The object id of the Custom Locations Entra ID application for your tenant. If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions. ```sh az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv``` | `string` | `null` | no |
| resource\_group\_name | The name of the Resource Group that will be created for the resources. | `string` | `null` | no |
| resource\_group\_tags | The tags to add to the resources. | `map(string)` | `null` | no |
| should\_add\_current\_user\_cluster\_admin | Gives the current logged in user cluster-admin permissions with the new cluster. | `bool` | `true` | no |
| should\_create\_anonymous\_broker\_listener | Whether to enable an insecure anonymous AIO MQ Broker Listener. Should only be used for dev or test environments. | `bool` | `false` | no |
| should\_create\_azure\_functions | Whether to create Azure Functions for the cluster | `bool` | `false` | no |
| should\_enable\_opc\_ua\_simulator | Whether to deploy the OPC UA Simulator to the cluster | `bool` | `true` | no |
| should\_enable\_otel\_collector | Whether to deploy the OpenTelemetry Collector and Azure Monitor ConfigMap (optionally used) | `bool` | `true` | no |
| should\_get\_custom\_locations\_oid | Whether to get Custom Locations Object ID using Terraform's azuread provider. (Otherwise, provided by 'custom\_locations\_oid' or `az connectedk8s enable-features` for custom-locations on cluster setup if not provided.) | `bool` | `true` | no |
| use\_existing\_resource\_group | Whether to use an existing resource group instead of creating a new one. When true, the component will look up a resource group with the specified or generated name instead of creating it. | `bool` | `false` | no |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
