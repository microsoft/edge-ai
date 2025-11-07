<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# PostgreSQL Flexible Server Internal Module

Creates Azure PostgreSQL Flexible Server with TimescaleDB support,
private networking, and database configurations.

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
| [azurerm_postgresql_flexible_server.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server) | resource |
| [azurerm_postgresql_flexible_server_configuration.extensions](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_configuration.timescaledb](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_database.databases](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_database) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| admin\_password | Administrator password for PostgreSQL server. | `string` | n/a | yes |
| admin\_username | Administrator username for PostgreSQL server. | `string` | n/a | yes |
| backup\_retention\_days | Number of days to retain backups. | `number` | n/a | yes |
| databases | Map of databases to create with collation and charset. | ```map(object({ collation = string charset = string }))``` | n/a | yes |
| delegated\_subnet\_id | Subnet ID with delegation to Microsoft.DBforPostgreSQL/flexibleServers. | `string` | n/a | yes |
| environment | Environment name: dev, test, or prod. | `string` | n/a | yes |
| extensions | List of PostgreSQL extensions to enable. | `list(string)` | n/a | yes |
| instance | Instance identifier for resource uniqueness. | `string` | n/a | yes |
| location | Azure region for PostgreSQL server deployment. | `string` | n/a | yes |
| postgres\_version | PostgreSQL server version. | `string` | n/a | yes |
| private\_dns\_zone\_id | Private DNS zone ID for privatelink.postgres.database.azure.com. | `string` | n/a | yes |
| resource\_group | Resource group object containing name and id. | ```object({ name = string })``` | n/a | yes |
| resource\_prefix | Prefix for resource naming. | `string` | n/a | yes |
| should\_enable\_extensions | Whether to enable PostgreSQL extensions via azure.extensions. | `bool` | n/a | yes |
| should\_enable\_geo\_redundant\_backup | Whether to enable geo-redundant backups. | `bool` | n/a | yes |
| should\_enable\_timescaledb | Whether to enable TimescaleDB extension. | `bool` | n/a | yes |
| sku\_name | SKU name for PostgreSQL server. | `string` | n/a | yes |
| storage\_mb | Storage size in megabytes. | `number` | n/a | yes |
| zone | Availability zone for PostgreSQL server deployment. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| connection\_info | PostgreSQL connection information. |
| databases | Map of created PostgreSQL databases. |
| postgresql\_server | PostgreSQL Flexible Server object. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
