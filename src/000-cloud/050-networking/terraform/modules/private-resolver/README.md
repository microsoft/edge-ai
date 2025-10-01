<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Private Resolver for VPN Client DNS Resolution

Deploys Azure Private Resolver with inbound endpoints to enable VPN clients
to resolve private DNS zones for Azure services behind private endpoints.
This solves the common issue where VPN clients cannot resolve private endpoints.

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
| [azurerm_private_dns_resolver.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver) | resource |
| [azurerm_private_dns_resolver_inbound_endpoint.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_inbound_endpoint) | resource |
| [azurerm_subnet.resolver_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_nat_gateway_association.resolver](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| default\_outbound\_access\_enabled | Whether to enable default outbound internet access for the Private Resolver subnet | `bool` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| nat\_gateway\_id | NAT gateway resource id for associating the resolver subnet | `string` | n/a | yes |
| resolver\_subnet\_address\_prefix | Address prefix for the Private Resolver subnet (e.g., '10.0.254.0/28') | `string` | n/a | yes |
| resource\_group | Resource group object containing name and id | ```object({ name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| virtual\_network | Virtual network object containing id and name | ```object({ id = string name = string })``` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| dns\_server\_ip | The IP address to use as DNS server for VNet configuration |
| inbound\_endpoint | The inbound endpoint for DNS resolution |
| private\_resolver | The Azure Private Resolver resource |
| resolver\_subnet | The subnet created for the Private Resolver |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
