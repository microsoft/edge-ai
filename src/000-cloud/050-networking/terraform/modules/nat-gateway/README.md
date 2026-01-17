<!-- BEGIN_TF_DOCS -->
# NAT Gateway

Provision a reusable NAT gateway with configurable public IP resources
for managed outbound access.

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

| Name                                                                                                                                                                | Type     |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| [azurerm_nat_gateway.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway)                                             | resource |
| [azurerm_nat_gateway_public_ip_association.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway_public_ip_association) | resource |
| [azurerm_public_ip.nat](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip)                                                  | resource |

## Inputs

| Name                       | Description                                                                                        | Type                                        | Default | Required |
|----------------------------|----------------------------------------------------------------------------------------------------|---------------------------------------------|---------|:--------:|
| availability\_zones        | Availability zones for NAT gateway resources when zone-redundancy is required (example: ['1','2']) | `list(string)`                              | n/a     |   yes    |
| environment                | Environment for all resources in this module: dev, test, or prod                                   | `string`                                    | n/a     |   yes    |
| idle\_timeout\_in\_minutes | Idle timeout in minutes for connections through the NAT gateway                                    | `number`                                    | n/a     |   yes    |
| instance                   | Instance identifier for naming resources: 001, 002, etc                                            | `string`                                    | n/a     |   yes    |
| location                   | Location for all resources in this module                                                          | `string`                                    | n/a     |   yes    |
| public\_ip\_count          | Number of public IP addresses to associate with the NAT gateway                                    | `number`                                    | n/a     |   yes    |
| resource\_group            | Resource group object containing name and id                                                       | ```object({ id = string name = string })``` | n/a     |   yes    |
| resource\_prefix           | Prefix for all resources in this module                                                            | `string`                                    | n/a     |   yes    |

## Outputs

| Name         | Description                                                       |
|--------------|-------------------------------------------------------------------|
| nat\_gateway | The NAT gateway resource                                          |
| public\_ips  | Public IP resources associated with the NAT gateway keyed by name |
<!-- END_TF_DOCS -->
