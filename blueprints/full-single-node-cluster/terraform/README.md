<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Full Single Node Cluster Blueprint

This blueprint deploys a complete Azure IoT Operations environment with all cloud and edge components
for a single-node cluster deployment, including observability, messaging, and data management.

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
| cloud\_azureml | ../../../src/000-cloud/080-azureml/terraform | n/a |
| cloud\_data | ../../../src/000-cloud/030-data/terraform | n/a |
| cloud\_kubernetes | ../../../src/000-cloud/070-kubernetes/terraform | n/a |
| cloud\_messaging | ../../../src/000-cloud/040-messaging/terraform | n/a |
| cloud\_networking | ../../../src/000-cloud/050-networking/terraform | n/a |
| cloud\_observability | ../../../src/000-cloud/020-observability/terraform | n/a |
| cloud\_resource\_group | ../../../src/000-cloud/000-resource-group/terraform | n/a |
| cloud\_security\_identity | ../../../src/000-cloud/010-security-identity/terraform | n/a |
| cloud\_vm\_host | ../../../src/000-cloud/051-vm-host/terraform | n/a |
| cloud\_vpn\_gateway | ../../../src/000-cloud/055-vpn-gateway/terraform | n/a |
| edge\_assets | ../../../src/100-edge/111-assets/terraform | n/a |
| edge\_azureml | ../../../src/100-edge/140-azureml/terraform | n/a |
| edge\_cncf\_cluster | ../../../src/100-edge/100-cncf-cluster/terraform | n/a |
| edge\_iot\_ops | ../../../src/100-edge/110-iot-ops/terraform | n/a |
| edge\_messaging | ../../../src/100-edge/130-messaging/terraform | n/a |
| edge\_observability | ../../../src/100-edge/120-observability/terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| acr\_sku | SKU name for the Azure Container Registry | `string` | `"Premium"` | no |
| aio\_features | AIO instance features with mode ('Stable', 'Preview', 'Disabled') and settings ('Enabled', 'Disabled') | ```map(object({ mode = optional(string) settings = optional(map(string)) }))``` | `null` | no |
| aks\_should\_enable\_private\_cluster | Whether to enable private cluster mode for AKS | `bool` | `true` | no |
| aks\_should\_enable\_private\_cluster\_public\_fqdn | Whether to create a private cluster public FQDN for AKS | `bool` | `false` | no |
| asset\_endpoint\_profiles | List of asset endpoint profiles to create; otherwise, an empty list | ```list(object({ name = string target_address = string endpoint_profile_type = optional(string) method = optional(string) should_enable_opc_asset_discovery = optional(bool) opc_additional_config_string = optional(string) }))``` | `[]` | no |
| assets | List of assets to create; otherwise, an empty list | ```list(object({ asset_endpoint_profile_ref = string datasets = optional(list(object({ data_points = list(object({ data_point_configuration = optional(string) data_source = string name = string observability_mode = optional(string) })) name = string })), []) default_datasets_configuration = optional(string) description = optional(string) display_name = optional(string) documentation_uri = optional(string) enabled = optional(bool) hardware_revision = optional(string) manufacturer = optional(string) manufacturer_uri = optional(string) model = optional(string) name = string product_code = optional(string) serial_number = optional(string) software_revision = optional(string) }))``` | `[]` | no |
| azureml\_ml\_workload\_subjects | Custom Kubernetes service account subjects for AzureML workload federation. Example: ['system:serviceaccount:azureml:azureml-workload', 'system:serviceaccount:osmo:osmo-workload'] | `list(string)` | `null` | no |
| azureml\_registry\_should\_enable\_public\_network\_access | Whether to enable public network access to the Azure Machine Learning registry when deployed | `bool` | `true` | no |
| azureml\_should\_create\_compute\_cluster | Whether to create a compute cluster for Azure Machine Learning training workloads | `bool` | `true` | no |
| azureml\_should\_create\_ml\_workload\_identity | Whether to create a user-assigned managed identity for AzureML workload federation. | `bool` | `false` | no |
| azureml\_should\_deploy\_registry | Whether to deploy Azure Machine Learning registry resources alongside the workspace | `bool` | `false` | no |
| azureml\_should\_enable\_private\_endpoint | Whether to enable a private endpoint for the Azure Machine Learning workspace | `bool` | `false` | no |
| azureml\_should\_enable\_public\_network\_access | Whether to enable public network access to the Azure Machine Learning workspace | `bool` | `true` | no |
| certificate\_subject | Certificate subject information for auto-generated certificates | ```object({ common_name = optional(string, "Full Single Node VPN Gateway Root Certificate") organization = optional(string, "Edge AI Accelerator") organizational_unit = optional(string, "IT") country = optional(string, "US") province = optional(string, "WA") locality = optional(string, "Redmond") })``` | `{}` | no |
| certificate\_validity\_days | Validity period in days for auto-generated certificates | `number` | `365` | no |
| custom\_locations\_oid | The object id of the Custom Locations Entra ID application for your tenant If none is provided, the script attempts to retrieve this value which requires 'Application.Read.All' or 'Directory.Read.All' permissions ```sh az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv``` | `string` | `null` | no |
| existing\_certificate\_name | Name of the existing certificate in Key Vault when vpn\_gateway\_should\_generate\_ca is false | `string` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| nat\_gateway\_idle\_timeout\_minutes | Idle timeout in minutes for NAT gateway connections | `number` | `4` | no |
| nat\_gateway\_public\_ip\_count | Number of public IP addresses to associate with the NAT gateway (example: 2) | `number` | `1` | no |
| nat\_gateway\_zones | Availability zones for NAT gateway resources when zone redundancy is required (example: ['1','2']) | `list(string)` | `[]` | no |
| node\_count | Number of nodes for the agent pool in the AKS cluster | `number` | `1` | no |
| node\_pools | Additional node pools for the AKS cluster; map key is used as the node pool name | ```map(object({ node_count = number vm_size = string subnet_address_prefixes = list(string) pod_subnet_address_prefixes = list(string) node_taints = optional(list(string), []) enable_auto_scaling = optional(bool, false) min_count = optional(number, null) max_count = optional(number, null) }))``` | `{}` | no |
| node\_vm\_size | VM size for the agent pool in the AKS cluster | `string` | `"Standard_D8ds_v5"` | no |
| resolver\_subnet\_address\_prefix | Address prefix for the private resolver subnet; must be /28 or larger and not overlap with other subnets | `string` | `"10.0.9.0/28"` | no |
| resource\_group\_name | Name of the resource group to create or use. Otherwise, 'rg-{resource\_prefix}-{environment}-{instance}' | `string` | `null` | no |
| should\_add\_current\_user\_cluster\_admin | Whether to give the current signed-in user cluster-admin permissions on the new cluster | `bool` | `true` | no |
| should\_create\_aks | Whether to deploy Azure Kubernetes Service | `bool` | `false` | no |
| should\_create\_aks\_identity | Whether to create a user-assigned identity for the AKS cluster when using custom private DNS zones | `bool` | `false` | no |
| should\_create\_anonymous\_broker\_listener | Whether to enable an insecure anonymous AIO MQ broker listener; use only for dev or test environments | `bool` | `false` | no |
| should\_create\_azure\_functions | Whether to create the Azure Functions resources including the App Service plan | `bool` | `false` | no |
| should\_deploy\_azureml | Whether to deploy the Azure Machine Learning workspace and optional compute cluster | `bool` | `false` | no |
| should\_deploy\_edge\_azureml | Whether to deploy the Azure Machine Learning edge extension when Azure ML is enabled | `bool` | `false` | no |
| should\_deploy\_resource\_sync\_rules | Whether to deploy resource sync rules | `bool` | `true` | no |
| should\_enable\_key\_vault\_public\_network\_access | Whether to enable public network access for the Key Vault | `bool` | `true` | no |
| should\_enable\_managed\_outbound\_access | Whether to enable managed outbound egress via NAT gateway instead of platform default internet access | `bool` | `true` | no |
| should\_enable\_oidc\_issuer | Whether to enable the OIDC issuer URL for the cluster | `bool` | `true` | no |
| should\_enable\_opc\_ua\_simulator | Whether to deploy the OPC UA simulator to the cluster | `bool` | `false` | no |
| should\_enable\_private\_endpoints | Whether to enable private endpoints for Key Vault and the storage account | `bool` | `false` | no |
| should\_enable\_private\_resolver | Whether to enable Azure Private Resolver for VPN client DNS resolution of private endpoints | `bool` | `false` | no |
| should\_enable\_storage\_public\_network\_access | Whether to enable public network access for the storage account | `bool` | `true` | no |
| should\_enable\_vpn\_gateway | Whether to create a VPN gateway for secure access to private endpoints | `bool` | `false` | no |
| should\_enable\_workload\_identity | Whether to enable Azure AD workload identity for the cluster | `bool` | `true` | no |
| should\_get\_custom\_locations\_oid | Whether to get the Custom Locations object ID using Terraform's azuread provider Otherwise, provide 'custom\_locations\_oid' or rely on `az connectedk8s enable-features` during cluster setup | `bool` | `true` | no |
| storage\_account\_is\_hns\_enabled | Whether to enable hierarchical namespace on the storage account when Azure Machine Learning is not deployed; automatically forced to false when should\_deploy\_azureml is true | `bool` | `true` | no |
| use\_existing\_resource\_group | Whether to use an existing resource group with the provided or computed name instead of creating a new one | `bool` | `false` | no |
| vpn\_gateway\_config | VPN gateway configuration including SKU, generation, client address pool, and supported protocols | ```object({ sku = optional(string, "VpnGw1") generation = optional(string, "Generation1") client_address_pool = optional(list(string), ["192.168.200.0/24"]) protocols = optional(list(string), ["OpenVPN", "IkeV2"]) })``` | `{}` | no |
| vpn\_gateway\_should\_generate\_ca | Whether to generate a new CA certificate; when false, uses an existing certificate from Key Vault | `bool` | `true` | no |
| vpn\_gateway\_should\_use\_azure\_ad\_auth | Whether to use Azure AD authentication for the VPN gateway; otherwise, certificate authentication is used | `bool` | `true` | no |
| vpn\_gateway\_subnet\_address\_prefixes | Address prefixes for the GatewaySubnet; must be /27 or larger | `list(string)` | ```[ "10.0.2.0/27" ]``` | no |
| vpn\_site\_connections | Site-to-site VPN site definitions. Use non-overlapping on-premises address spaces and reference shared keys via shared\_key\_reference | ```list(object({ name = string address_spaces = list(string) shared_key_reference = string connection_mode = optional(string, "Default") dpd_timeout_seconds = optional(number) gateway_fqdn = optional(string) gateway_ip_address = optional(string) ike_protocol = optional(string, "IKEv2") use_policy_based_selectors = optional(bool, false) bgp_settings = optional(object({ asn = number peer_address = string peer_weight = optional(number) })) ipsec_policy = optional(object({ dh_group = string ike_encryption = string ike_integrity = string ipsec_encryption = string ipsec_integrity = string pfs_group = string sa_datasize_kb = optional(number) sa_lifetime_seconds = optional(number) })) }))``` | `[]` | no |
| vpn\_site\_default\_ipsec\_policy | Fallback IPsec policy applied when site definitions omit ipsec\_policy overrides | ```object({ dh_group = string ike_encryption = string ike_integrity = string ipsec_encryption = string ipsec_integrity = string pfs_group = string sa_datasize_kb = optional(number) sa_lifetime_seconds = optional(number) })``` | `null` | no |
| vpn\_site\_shared\_keys | Pre-shared keys for site definitions keyed by shared\_key\_reference. Source values from secure secret storage | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| arc\_connected\_cluster | Azure Arc connected cluster resources. |
| assets | IoT asset resources. |
| azure\_iot\_operations | Azure IoT Operations deployment details. |
| azureml\_compute\_cluster | Azure Machine Learning compute cluster resources. |
| azureml\_extension | Azure Machine Learning extension for AKS cluster integration. |
| azureml\_inference\_cluster | Azure Machine Learning inference cluster compute target for AKS integration. |
| azureml\_workspace | Azure Machine Learning workspace resources. |
| cluster\_connection | Commands and information to connect to the deployed cluster. |
| container\_registry | Azure Container Registry resources. |
| data\_storage | Data storage resources. |
| deployment\_summary | Summary of the deployment configuration. |
| kubernetes | Azure Kubernetes Service resources. |
| messaging | Cloud messaging resources. |
| nat\_gateway | NAT gateway resource when managed outbound access is enabled. |
| nat\_gateway\_public\_ips | Public IP resources associated with the NAT gateway keyed by name. |
| observability | Monitoring and observability resources. |
| private\_resolver\_dns\_ip | Private Resolver DNS IP address for VPN client configuration. |
| security\_identity | Security and identity resources. |
| vm\_host | Virtual machine host resources. |
| vpn\_client\_connection\_info | VPN client connection information including download URLs. |
| vpn\_gateway | VPN Gateway configuration when enabled. |
| vpn\_gateway\_public\_ip | VPN Gateway public IP address for client configuration. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
