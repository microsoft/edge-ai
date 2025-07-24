<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Dual Peered Single Node Cluster Blueprint

This blueprint deploys two complete Azure IoT Operations environments with all cloud and edge components
for single-node cluster deployments with different address spaces and VNet peering between them.
Each cluster operates independently but can communicate through the peered virtual networks.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.8.0 |
| local | >= 2.0.0 |
| tls | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.8.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_virtual_network_peering.cluster_a_to_cluster_b](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) | resource |
| [azurerm_virtual_network_peering.cluster_b_to_cluster_a](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) | resource |

## Modules

| Name | Source | Version |
|------|--------|---------|
| cluster\_a\_cloud\_data | ../../../src/000-cloud/030-data/terraform | n/a |
| cluster\_a\_cloud\_kubernetes | ../../../src/000-cloud/070-kubernetes/terraform | n/a |
| cluster\_a\_cloud\_messaging | ../../../src/000-cloud/040-messaging/terraform | n/a |
| cluster\_a\_cloud\_networking | ../../../src/000-cloud/050-networking/terraform | n/a |
| cluster\_a\_cloud\_observability | ../../../src/000-cloud/020-observability/terraform | n/a |
| cluster\_a\_cloud\_resource\_group | ../../../src/000-cloud/000-resource-group/terraform | n/a |
| cluster\_a\_cloud\_security\_identity | ../../../src/000-cloud/010-security-identity/terraform | n/a |
| cluster\_a\_cloud\_vm\_host | ../../../src/000-cloud/051-vm-host/terraform | n/a |
| cluster\_a\_edge\_assets | ../../../src/100-edge/111-assets/terraform | n/a |
| cluster\_a\_edge\_cncf\_cluster | ../../../src/100-edge/100-cncf-cluster/terraform | n/a |
| cluster\_a\_edge\_iot\_ops | ../../../src/100-edge/110-iot-ops/terraform | n/a |
| cluster\_a\_edge\_messaging | ../../../src/100-edge/130-messaging/terraform | n/a |
| cluster\_a\_edge\_observability | ../../../src/100-edge/120-observability/terraform | n/a |
| cluster\_b\_cloud\_data | ../../../src/000-cloud/030-data/terraform | n/a |
| cluster\_b\_cloud\_messaging | ../../../src/000-cloud/040-messaging/terraform | n/a |
| cluster\_b\_cloud\_networking | ../../../src/000-cloud/050-networking/terraform | n/a |
| cluster\_b\_cloud\_observability | ../../../src/000-cloud/020-observability/terraform | n/a |
| cluster\_b\_cloud\_resource\_group | ../../../src/000-cloud/000-resource-group/terraform | n/a |
| cluster\_b\_cloud\_security\_identity | ../../../src/000-cloud/010-security-identity/terraform | n/a |
| cluster\_b\_cloud\_vm\_host | ../../../src/000-cloud/051-vm-host/terraform | n/a |
| cluster\_b\_edge\_assets | ../../../src/100-edge/111-assets/terraform | n/a |
| cluster\_b\_edge\_cncf\_cluster | ../../../src/100-edge/100-cncf-cluster/terraform | n/a |
| cluster\_b\_edge\_iot\_ops | ../../../src/100-edge/110-iot-ops/terraform | n/a |
| cluster\_b\_edge\_messaging | ../../../src/100-edge/130-messaging/terraform | n/a |
| cluster\_b\_edge\_observability | ../../../src/100-edge/120-observability/terraform | n/a |
| custom\_script\_deployment | ./modules/custom-script-deployment | n/a |
| key\_vault\_publisher | ./modules/key-vault-publisher | n/a |
| mqtt\_configuration | ./modules/mqtt-configuration | n/a |
| secret\_provider\_class | ./modules/secret-provider-class | n/a |
| shared\_cloud\_acr | ../../../src/000-cloud/060-acr/terraform | n/a |
| shared\_cloud\_resource\_group | ../../../src/000-cloud/000-resource-group/terraform | n/a |
| terraform\_certificate\_generation | ./modules/terraform-certificate-generation | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod. | `string` | n/a | yes |
| location | Location for all resources in this module. | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module. | `string` | n/a | yes |
| aio\_features | AIO Instance features with mode ('Stable', 'Preview', 'Disabled') and settings ('Enabled', 'Disabled'). | ```map(object({ mode = optional(string) settings = optional(map(string)) }))``` | `null` | no |
| asset\_endpoint\_profiles | List of asset endpoint profiles to create. Otherwise, an empty list. | ```list(object({ name = string target_address = string endpoint_profile_type = optional(string) method = optional(string) should_enable_opc_asset_discovery = optional(bool) opc_additional_config_string = optional(string) }))``` | `[]` | no |
| assets | List of assets to create. Otherwise, an empty list. | ```list(object({ asset_endpoint_profile_ref = string datasets = optional(list(object({ data_points = list(object({ data_point_configuration = optional(string) data_source = string name = string observability_mode = optional(string) })) name = string })), []) default_datasets_configuration = optional(string) description = optional(string) display_name = optional(string) documentation_uri = optional(string) enabled = optional(bool) hardware_revision = optional(string) manufacturer = optional(string) manufacturer_uri = optional(string) model = optional(string) name = string product_code = optional(string) serial_number = optional(string) software_revision = optional(string) }))``` | `[]` | no |
| cluster\_a\_virtual\_network\_config | Configuration for Cluster A virtual network including address space and subnet prefix. | ```object({ address_space = string subnet_address_prefix = string })``` | ```{ "address_space": "10.1.0.0/16", "subnet_address_prefix": "10.1.1.0/24" }``` | no |
| cluster\_b\_virtual\_network\_config | Configuration for Cluster B virtual network including address space and subnet prefix. | ```object({ address_space = string subnet_address_prefix = string })``` | ```{ "address_space": "10.2.0.0/16", "subnet_address_prefix": "10.2.1.0/24" }``` | no |
| custom\_locations\_oid | The object id of the Custom Locations Entra ID application for your tenant. If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions. ```sh az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv``` | `string` | `null` | no |
| enterprise\_broker\_port | The port number for the enterprise MQTT broker listener | `number` | `28883` | no |
| enterprise\_broker\_tls\_cert\_secret\_name | The name of the Kubernetes secret containing the broker tls certificate | `string` | `"broker-tls-cert"` | no |
| enterprise\_client\_ca\_configmap\_name | The name of the Kubernetes configmap containing the client CA certificate | `string` | `"client-ca"` | no |
| external\_certificates | External certificates to use instead of generating them with Terraform. When null, certificates will be generated using the terraform-certificate-generation module. | ```object({ server_root_ca_cert = string server_root_ca_key = string server_intermediate_ca_cert = string server_intermediate_ca_key = string server_leaf_cert = string server_leaf_key = string client_root_ca_cert = string client_root_ca_key = string client_intermediate_ca_cert = string client_intermediate_ca_key = string client_leaf_cert = string client_leaf_key = string })``` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| resource\_group\_name\_a | The name for the Cluster A resource group. If not provided, a default name will be generated using resource\_prefix, environment, and instance. | `string` | `null` | no |
| resource\_group\_name\_b | The name for the Cluster B resource group. If not provided, a default name will be generated using resource\_prefix, environment, and instance. | `string` | `null` | no |
| should\_create\_acr\_private\_endpoint | Should create a private endpoint for the Azure Container Registry. Default is false. | `bool` | `false` | no |
| should\_create\_aks | Should create Azure Kubernetes Service. Default is false. | `bool` | `false` | no |
| should\_create\_anonymous\_broker\_listener | Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments) | `bool` | `false` | no |
| should\_create\_azure\_functions | Whether to create Azure Functions for the clusters. | `bool` | `false` | no |
| should\_deploy\_client\_technology\_script | Whether to deploy the client-technology.sh script to Cluster B VM. | `bool` | `true` | no |
| should\_deploy\_custom\_scripts | Whether to deploy the custom scripts (server-central.sh and client-technology.sh) to the VMs. | `bool` | `true` | no |
| should\_deploy\_resource\_sync\_rules | Deploys resource sync rules if set to true. | `bool` | `false` | no |
| should\_deploy\_server\_central\_script | Whether to deploy the server-central.sh script to Cluster A VM. | `bool` | `true` | no |
| should\_enable\_opc\_ua\_simulator | Should create an OPC UA Simulator. Default is false. | `bool` | `false` | no |
| should\_get\_custom\_locations\_oid | Whether to get Custom Locations Object ID using Terraform's azuread provider. (Otherwise, provided by 'custom\_locations\_oid' or `az connectedk8s enable-features` for custom-locations on cluster setup if not provided.) | `bool` | `true` | no |
| site\_client\_secret\_name | The name of the Kubernetes secret containing the client certificate and key | `string` | `"client-secret"` | no |
| site\_tls\_ca\_configmap\_name | The name of the Kubernetes configmap containing the TLS CA certificate | `string` | `"tls-ca-configmap"` | no |
| use\_existing\_resource\_group\_a | Whether to use an existing resource group for Cluster A instead of creating a new one. When true, the component will look up a resource group with the specified or generated name instead of creating it. | `bool` | `false` | no |
| use\_existing\_resource\_group\_b | Whether to use an existing resource group for Cluster B instead of creating a new one. When true, the component will look up a resource group with the specified or generated name instead of creating it. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| client\_technology\_script\_deployment | The client technology script deployment extension on Cluster B. |
| cluster\_a\_aio\_instance | The Cluster A AIO instance. |
| cluster\_a\_arc\_connected\_cluster | The Cluster A Arc connected cluster. |
| cluster\_a\_azure\_arc\_proxy\_command | The AZ CLI command to proxy to the Cluster A Arc Connected cluster. |
| cluster\_a\_resource\_group | The Cluster A resource group. |
| cluster\_a\_virtual\_network | The Cluster A virtual network. |
| cluster\_b\_aio\_instance | The Cluster B AIO instance. |
| cluster\_b\_arc\_connected\_cluster | The Cluster B Arc connected cluster. |
| cluster\_b\_azure\_arc\_proxy\_command | The AZ CLI command to proxy to the Cluster B Arc Connected cluster. |
| cluster\_b\_resource\_group | The Cluster B resource group. |
| cluster\_b\_virtual\_network | The Cluster B virtual network. |
| secret\_provider\_class\_status | Status of the secret provider class configuration. |
| server\_central\_script\_deployment | The server central script deployment extension on Cluster A. |
| vnet\_peering\_cluster\_a\_to\_cluster\_b | The virtual network peering from Cluster A to Cluster B. |
| vnet\_peering\_cluster\_b\_to\_cluster\_a | The virtual network peering from Cluster B to Cluster A. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
