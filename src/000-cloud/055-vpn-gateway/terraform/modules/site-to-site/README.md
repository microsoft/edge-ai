<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Site-to-Site VPN Connections

Creates Azure Local Network Gateways and VPN Gateway Connections for
on-premises sites defined by the parent component.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm | >= 4.51.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.51.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_local_network_gateway.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/local_network_gateway) | resource |
| [azurerm_virtual_network_gateway_connection.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway_connection) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module | `string` | n/a | yes |
| instance | Instance identifier for naming resources | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_group | Resource group object containing name and id | ```object({ id = string name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| shared\_keys | Pre-shared keys mapped by site shared key reference | `map(string)` | n/a | yes |
| sites | Site-to-site VPN connection definitions including addressing, shared key references, and optional policy tuning | ```list(object({ name = string address_spaces = list(string) shared_key_reference = string connection_mode = optional(string) dpd_timeout_seconds = optional(number) gateway_fqdn = optional(string) gateway_ip_address = optional(string) ike_protocol = optional(string) use_policy_based_selectors = optional(bool) bgp_settings = optional(object({ asn = number peer_address = string peer_weight = optional(number) })) ipsec_policy = optional(object({ dh_group = string ike_encryption = string ike_integrity = string ipsec_encryption = string ipsec_integrity = string pfs_group = string sa_datasize_kb = optional(number) sa_lifetime_seconds = optional(number) })) }))``` | n/a | yes |
| vpn\_gateway\_id | ID of the Azure Virtual Network Gateway used for site-to-site connections | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| local\_network\_gateways | Local network gateway resources keyed by site name |
| site\_connections | Site-to-site VPN connections keyed by site name |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
