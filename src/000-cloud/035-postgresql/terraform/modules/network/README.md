<!-- BEGIN_TF_DOCS -->
# PostgreSQL Networking Module

Creates delegated subnet for PostgreSQL Flexible Server

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm   | >= 4.51.0       |

## Providers

| Name    | Version   |
|---------|-----------|
| azurerm | >= 4.51.0 |

## Resources

| Name                                                                                                                                                                                    | Type     |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| [azurerm_private_dns_zone.postgres](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone)                                                   | resource |
| [azurerm_private_dns_zone_virtual_network_link.postgres](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link)         | resource |
| [azurerm_subnet.postgres](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet)                                                                       | resource |
| [azurerm_subnet_nat_gateway_association.postgres](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association)                       | resource |
| [azurerm_subnet_network_security_group_association.postgres](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |

## Inputs

| Name                               | Description                                                                   | Type                                        | Default | Required |
|------------------------------------|-------------------------------------------------------------------------------|---------------------------------------------|---------|:--------:|
| default\_outbound\_access\_enabled | Whether to enable default outbound internet access for PostgreSQL subnet.     | `bool`                                      | n/a     |   yes    |
| environment                        | Environment for all resources in this module: dev, test, or prod.             | `string`                                    | n/a     |   yes    |
| instance                           | Instance identifier for naming resources: 001, 002, etc.                      | `string`                                    | n/a     |   yes    |
| nat\_gateway                       | NAT gateway object from networking component for managed outbound access.     | ```object({ id = string name = string })``` | n/a     |   yes    |
| network\_security\_group           | Network security group object to associate with PostgreSQL subnet.            | ```object({ id = string })```               | n/a     |   yes    |
| resource\_group                    | Resource group object containing name and id.                                 | ```object({ name = string })```             | n/a     |   yes    |
| resource\_prefix                   | Prefix for all resources in this module.                                      | `string`                                    | n/a     |   yes    |
| should\_create\_private\_dns\_zone | Whether to create private DNS zone for PostgreSQL.                            | `bool`                                      | n/a     |   yes    |
| should\_enable\_nat\_gateway       | Whether to associate PostgreSQL subnet with a NAT gateway for managed egress. | `bool`                                      | n/a     |   yes    |
| subnet\_address\_prefixes          | Address prefixes for the PostgreSQL delegated subnet.                         | `list(string)`                              | n/a     |   yes    |
| virtual\_network                   | Virtual network object containing name and id.                                | ```object({ name = string id = string })``` | n/a     |   yes    |

## Outputs

| Name                   | Description                                                  |
|------------------------|--------------------------------------------------------------|
| postgres\_subnet       | The delegated subnet created for PostgreSQL Flexible Server. |
| private\_dns\_zone\_id | Private DNS zone ID if created.                              |
<!-- END_TF_DOCS -->
