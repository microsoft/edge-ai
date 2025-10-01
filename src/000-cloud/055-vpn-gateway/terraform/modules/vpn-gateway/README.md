<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# VPN Gateway Implementation

Creates VPN Gateway with Point-to-Site configuration, GatewaySubnet,
public IP, and private DNS zones for Azure services.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.8.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_public_ip.vpn_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_subnet.gateway_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_virtual_network_gateway.vpn](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| azure\_ad\_config | Azure AD configuration for VPN Gateway authentication | ```object({ tenant_id = string audience = string issuer = string })``` | n/a | yes |
| default\_outbound\_access\_enabled | Whether to enable default outbound internet access for the VPN gateway subnet | `bool` | n/a | yes |
| environment | Environment for all resources in this module | `string` | n/a | yes |
| instance | Instance identifier for naming resources | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| resource\_group | Resource group object containing name and id | ```object({ id = string name = string location = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| root\_certificate\_name | Name of the root certificate for VPN authentication | `string` | n/a | yes |
| root\_certificate\_public\_data | Public certificate data for VPN authentication | `string` | n/a | yes |
| should\_use\_azure\_ad\_auth | Whether to use Azure AD authentication for VPN Gateway | `bool` | n/a | yes |
| virtual\_network | Virtual network object for VPN Gateway subnet creation | ```object({ id = string name = string })``` | n/a | yes |
| vpn\_gateway\_config | VPN Gateway configuration | ```object({ sku = string generation = string client_address_pool = list(string) protocols = list(string) })``` | n/a | yes |
| vpn\_gateway\_subnet\_address\_prefixes | Address prefixes for the GatewaySubnet | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| gateway\_subnet | The Gateway subnet information |
| public\_ip\_address | The public IP address of the VPN Gateway |
| vpn\_gateway | The VPN Gateway resource |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
