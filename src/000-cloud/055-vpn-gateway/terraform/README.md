<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# VPN Gateway

Creates a VPN Gateway with Point-to-Site configuration to provide secure
remote access to Azure services through private endpoints. Supports both
certificate-based and Azure Entra ID authentication methods.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm | >= 4.8.0 |
| tls | >= 4.0.6 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| certificate\_management | ./modules/certificate-management | n/a |
| site\_to\_site | ./modules/site-to-site | n/a |
| vpn\_gateway | ./modules/vpn-gateway | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_resource\_group | Resource group object containing name and id | ```object({ id = string name = string location = string })``` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| virtual\_network | Virtual network object for VPN Gateway subnet creation | ```object({ id = string name = string })``` | n/a | yes |
| azure\_ad\_config | Azure AD configuration for VPN Gateway authentication. tenant\_id is required when should\_use\_azure\_ad\_auth is true. audience defaults to Microsoft-registered app. issuer will default to `https://sts.windows.net/{tenant_id}/` when not provided | ```object({ tenant_id = optional(string) audience = optional(string, "c632b3df-fb67-4d84-bdcf-b95ad541b5c8") issuer = optional(string) })``` | `{}` | no |
| certificate\_subject | Certificate subject information for auto-generated certificates. Only used when should\_generate\_ca is true and should\_use\_azure\_ad\_auth is false | ```object({ common_name = optional(string, "VPN Gateway Root Certificate") organization = optional(string, "Edge AI Accelerator") organizational_unit = optional(string, "IT") country = optional(string, "US") province = optional(string, "WA") locality = optional(string, "Redmond") })``` | `{}` | no |
| certificate\_validity\_days | Validity period in days for auto-generated certificates. Only used when should\_generate\_ca is true and should\_use\_azure\_ad\_auth is false | `number` | `365` | no |
| default\_outbound\_access\_enabled | Whether to enable default outbound internet access for the VPN gateway subnet | `bool` | `false` | no |
| existing\_certificate\_name | Name of existing certificate in Key Vault when should\_generate\_ca is false. Required when should\_generate\_ca is false and should\_use\_azure\_ad\_auth is false | `string` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| key\_vault | Key Vault object for certificate storage. Required when using auto-generated certificates | ```object({ id = string name = string vault_uri = string })``` | `null` | no |
| should\_generate\_ca | Whether to generate a new CA certificate. When false, uses existing certificate from Key Vault. Only used when should\_use\_azure\_ad\_auth is false | `bool` | `true` | no |
| should\_use\_azure\_ad\_auth | Whether to use Azure AD authentication for VPN Gateway. When true, uses Azure AD authentication. When false, uses certificate authentication | `bool` | `true` | no |
| vpn\_gateway\_config | VPN Gateway configuration including SKU, generation, client address pool, and supported protocols | ```object({ sku = optional(string, "VpnGw1") generation = optional(string, "Generation1") client_address_pool = optional(list(string), ["192.168.200.0/24"]) protocols = optional(list(string), ["OpenVPN", "IkeV2"]) })``` | `{}` | no |
| vpn\_gateway\_subnet\_address\_prefixes | Address prefixes for the GatewaySubnet. Must be /27 or larger | `list(string)` | ```[ "10.0.2.0/27" ]``` | no |
| vpn\_site\_connections | Site-to-site VPN site definitions including on-premises device addressing and optional IPsec or BGP settings. Address spaces must not overlap with Azure VNets | ```list(object({ name = string address_spaces = list(string) shared_key_reference = string connection_mode = optional(string, "Default") dpd_timeout_seconds = optional(number) gateway_fqdn = optional(string) gateway_ip_address = optional(string) ike_protocol = optional(string, "IKEv2") use_policy_based_selectors = optional(bool, false) bgp_settings = optional(object({ asn = number peer_address = string peer_weight = optional(number) })) ipsec_policy = optional(object({ dh_group = string ike_encryption = string ike_integrity = string ipsec_encryption = string ipsec_integrity = string pfs_group = string sa_datasize_kb = optional(number) sa_lifetime_seconds = optional(number) })) }))``` | `[]` | no |
| vpn\_site\_default\_ipsec\_policy | Fallback IPsec configuration applied to site connections when they omit an ipsec\_policy override | ```object({ dh_group = string ike_encryption = string ike_integrity = string ipsec_encryption = string ipsec_integrity = string pfs_group = string sa_datasize_kb = optional(number) sa_lifetime_seconds = optional(number) })``` | `null` | no |
| vpn\_site\_shared\_keys | Pre-shared keys for site connections keyed by shared\_key\_reference. Store values in secure secret management systems | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| client\_connection\_info | Information for VPN client configuration |
| root\_certificate | The root certificate configuration for VPN clients. Only available when should\_use\_azure\_ad\_auth is false |
| vpn\_gateway | The VPN Gateway configuration and details |
| vpn\_gateway\_public\_ip | The public IP address of the VPN Gateway |
| vpn\_site\_connections | Site-to-site VPN connection metadata keyed by site name |
| vpn\_site\_local\_network\_gateways | Local network gateway metadata keyed by site name |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
