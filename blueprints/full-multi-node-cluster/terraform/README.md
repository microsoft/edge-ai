<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Full Multi Node Cluster Blueprint (Updated)

Deploys the complete Edge AI solution for a multi-node edge cluster, aligning module orchestration
with the single-node blueprint while preserving multi-node specific capabilities.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.8.0 |
| fabric | 1.3.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.8.0 |
| terraform | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_data.defer_arc_machine_prefix](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [azurerm_arc_machine.arc_machines](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/arc_machine) | data source |

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
| acr\_allow\_trusted\_services | Whether trusted Azure services can bypass ACR network rules | `bool` | `true` | no |
| acr\_allowed\_public\_ip\_ranges | CIDR ranges permitted to reach the ACR public endpoint | `list(string)` | `[]` | no |
| acr\_data\_endpoint\_enabled | Whether to enable the dedicated ACR data endpoint | `bool` | `true` | no |
| acr\_public\_network\_access\_enabled | Whether to enable the ACR public endpoint alongside private connectivity | `bool` | `false` | no |
| acr\_sku | SKU name for the Azure Container Registry | `string` | `"Premium"` | no |
| aio\_features | AIO instance features with mode ('Stable', 'Preview', 'Disabled') and settings ('Enabled', 'Disabled') | ```map(object({ mode = optional(string) settings = optional(map(string)) }))``` | `null` | no |
| aks\_private\_dns\_zone\_id | ID of the private DNS zone to use for AKS private cluster. Use 'system', 'none', or a resource ID | `string` | `null` | no |
| aks\_should\_enable\_private\_cluster | Whether to enable private cluster mode for AKS | `bool` | `false` | no |
| aks\_should\_enable\_private\_cluster\_public\_fqdn | Whether to create a private cluster public FQDN for AKS | `bool` | `false` | no |
| arc\_machine\_count | Number of Arc-enabled machines to target for the cluster when should\_use\_arc\_machines is true | `number` | `1` | no |
| arc\_machine\_name\_prefix | Prefix for the Arc-enabled machine names; otherwise resource\_prefix when should\_use\_arc\_machines is true | `string` | `null` | no |
| arc\_machine\_resource\_group\_name | Resource group name that contains the Arc-enabled servers when should\_use\_arc\_machines is true | `string` | `null` | no |
| asset\_endpoint\_profiles | List of asset endpoint profiles to create; otherwise, an empty list | ```list(object({ name = string target_address = string endpoint_profile_type = optional(string) method = optional(string) should_enable_opc_asset_discovery = optional(bool) opc_additional_config_string = optional(string) }))``` | `[]` | no |
| assets | List of assets to create; otherwise, an empty list | ```list(object({ asset_endpoint_profile_ref = string datasets = optional(list(object({ data_points = list(object({ data_point_configuration = optional(string) data_source = string name = string observability_mode = optional(string) })) name = string })), []) default_datasets_configuration = optional(string) description = optional(string) display_name = optional(string) documentation_uri = optional(string) enabled = optional(bool) hardware_revision = optional(string) manufacturer = optional(string) manufacturer_uri = optional(string) model = optional(string) name = string product_code = optional(string) serial_number = optional(string) software_revision = optional(string) }))``` | `[]` | no |
| azureml\_ml\_workload\_subjects | Custom Kubernetes service account subjects for AzureML workload federation. Example: ['system:serviceaccount:azureml:azureml-workload', 'system:serviceaccount:osmo:osmo-workload'] | `list(string)` | `null` | no |
| azureml\_registry\_should\_enable\_public\_network\_access | Whether to enable public network access to the Azure Machine Learning registry when deployed | `bool` | `true` | no |
| azureml\_should\_create\_compute\_cluster | Whether to create a compute cluster for Azure Machine Learning training workloads | `bool` | `true` | no |
| azureml\_should\_create\_ml\_workload\_identity | Whether to create a user-assigned managed identity for AzureML workload federation. | `bool` | `false` | no |
| azureml\_should\_deploy\_registry | Whether to deploy Azure Machine Learning registry resources alongside the workspace | `bool` | `false` | no |
| azureml\_should\_enable\_private\_endpoint | Whether to enable a private endpoint for the Azure Machine Learning workspace | `bool` | `false` | no |
| azureml\_should\_enable\_public\_network\_access | Whether to enable public network access to the Azure Machine Learning workspace | `bool` | `true` | no |
| certificate\_subject | Certificate subject information for auto-generated certificates | ```object({ common_name = optional(string, "Full Multi Node VPN Gateway Root Certificate") organization = optional(string, "Edge AI Accelerator") organizational_unit = optional(string, "IT") country = optional(string, "US") province = optional(string, "WA") locality = optional(string, "Redmond") })``` | `{}` | no |
| certificate\_validity\_days | Validity period in days for auto-generated certificates | `number` | `365` | no |
| cluster\_server\_host\_machine\_username | Username for the Arc or VM host machines that receive kube-config during setup Otherwise, resource\_prefix when the user exists on the machine | `string` | `null` | no |
| cluster\_server\_ip | IP address for the cluster server used by node machines when should\_use\_arc\_machines is true | `string` | `null` | no |
| custom\_locations\_oid | The object id of the Custom Locations Entra ID application for your tenant If none is provided, the script attempts to retrieve this value which requires 'Application.Read.All' or 'Directory.Read.All' permissions ```sh az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv``` | `string` | `null` | no |
| dns\_prefix | DNS prefix for the AKS cluster. When null a value is generated | `string` | `null` | no |
| enable\_auto\_scaling | Whether to enable auto-scaling for the default node pool | `bool` | `false` | no |
| existing\_certificate\_name | Name of the existing certificate in Key Vault when vpn\_gateway\_should\_generate\_ca is false | `string` | `null` | no |
| host\_machine\_count | Number of edge host virtual machines to create for the multi-node cluster | `number` | `3` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| max\_count | Maximum node count for the default node pool | `number` | `null` | no |
| min\_count | Minimum node count for the default node pool | `number` | `null` | no |
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
| should\_deploy\_resource\_sync\_rules | Whether to deploy resource sync rules | `bool` | `false` | no |
| should\_enable\_key\_vault\_public\_network\_access | Whether to enable public network access for the Key Vault | `bool` | `true` | no |
| should\_enable\_managed\_outbound\_access | Whether to enable managed outbound egress via NAT gateway instead of platform default internet access | `bool` | `true` | no |
| should\_enable\_oidc\_issuer | Whether to enable the OIDC issuer URL for the cluster | `bool` | `true` | no |
| should\_enable\_opc\_ua\_simulator | Whether to deploy the OPC UA simulator to the cluster | `bool` | `false` | no |
| should\_enable\_otel\_collector | Whether to deploy the OpenTelemetry Collector and Azure Monitor ConfigMap | `bool` | `true` | no |
| should\_enable\_private\_endpoints | Whether to enable private endpoints across Key Vault, storage, and observability resources so Prometheus ingestion remains on private link | `bool` | `false` | no |
| should\_enable\_private\_resolver | Whether to enable Azure Private Resolver for VPN client DNS resolution of private endpoints | `bool` | `false` | no |
| should\_enable\_storage\_public\_network\_access | Whether to enable public network access for the storage account | `bool` | `true` | no |
| should\_enable\_vpn\_gateway | Whether to create a VPN gateway for secure access to private endpoints | `bool` | `false` | no |
| should\_enable\_workload\_identity | Whether to enable Azure AD workload identity for the cluster | `bool` | `true` | no |
| should\_get\_custom\_locations\_oid | Whether to get the Custom Locations object ID using Terraform's azuread provider Otherwise, provide 'custom\_locations\_oid' or rely on `az connectedk8s enable-features` during cluster setup | `bool` | `true` | no |
| should\_use\_arc\_machines | Whether to orchestrate the cluster using existing Arc-enabled servers instead of deploying Azure virtual machines | `bool` | `false` | no |
| storage\_account\_is\_hns\_enabled | Whether to enable hierarchical namespace on the storage account when Azure Machine Learning is not deployed; automatically forced to false when should\_deploy\_azureml is true | `bool` | `true` | no |
| subnet\_address\_prefixes\_aks | Address prefixes for the AKS subnet | `list(string)` | ```[ "10.0.4.0/24" ]``` | no |
| subnet\_address\_prefixes\_aks\_pod | Address prefixes for the AKS pod subnet | `list(string)` | ```[ "10.0.5.0/24" ]``` | no |
| use\_existing\_resource\_group | Whether to use an existing resource group with the provided or computed name instead of creating a new one | `bool` | `false` | no |
| vpn\_gateway\_config | VPN gateway configuration including SKU, generation, client address pool, and supported protocols | ```object({ sku = optional(string, "VpnGw1") generation = optional(string, "Generation1") client_address_pool = optional(list(string), ["192.168.200.0/24"]) protocols = optional(list(string), ["OpenVPN", "IkeV2"]) })``` | `{}` | no |
| vpn\_gateway\_should\_generate\_ca | Whether to generate a new CA certificate; when false, uses an existing certificate from Key Vault | `bool` | `true` | no |
| vpn\_gateway\_should\_use\_azure\_ad\_auth | Whether to use Azure AD authentication for the VPN gateway; otherwise, certificate authentication is used | `bool` | `true` | no |
| vpn\_gateway\_subnet\_address\_prefixes | Address prefixes for the GatewaySubnet; must be /27 or larger | `list(string)` | ```[ "10.0.2.0/27" ]``` | no |
| vpn\_site\_connections | Site-to-site VPN connection definitions. Provide on-premises address spaces that do not overlap with Azure VNets | ```list(object({ name = string address_spaces = list(string) shared_key_reference = string connection_mode = optional(string, "Default") dpd_timeout_seconds = optional(number) gateway_fqdn = optional(string) gateway_ip_address = optional(string) ike_protocol = optional(string, "IKEv2") use_policy_based_selectors = optional(bool, false) bgp_settings = optional(object({ asn = number peer_address = string peer_weight = optional(number) })) ipsec_policy = optional(object({ dh_group = string ike_encryption = string ike_integrity = string ipsec_encryption = string ipsec_integrity = string pfs_group = string sa_datasize_kb = optional(number) sa_lifetime_seconds = optional(number) })) }))``` | `[]` | no |
| vpn\_site\_default\_ipsec\_policy | Fallback IPsec parameters applied when site definitions omit ipsec\_policy | ```object({ dh_group = string ike_encryption = string ike_integrity = string ipsec_encryption = string ipsec_integrity = string pfs_group = string sa_datasize_kb = optional(number) sa_lifetime_seconds = optional(number) })``` | `null` | no |
| vpn\_site\_shared\_keys | Pre-shared keys for site connections keyed by shared\_key\_reference. Manage values in secure secret stores | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| acr\_network\_posture | Azure Container Registry network posture metadata. |
| container\_registry | Azure Container Registry resources. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
