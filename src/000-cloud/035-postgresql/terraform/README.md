<!-- BEGIN_TF_DOCS -->
# PostgreSQL Flexible Server Component

Deploys Azure PostgreSQL Flexible Server with TimescaleDB support,
private networking, and optional geo-redundant backups.

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm   | >= 4.51.0       |

## Providers

| Name    | Version   |
|---------|-----------|
| azurerm | >= 4.51.0 |
| random  | n/a       |

## Resources

| Name                                                                                                                                        | Type     |
|---------------------------------------------------------------------------------------------------------------------------------------------|----------|
| [azurerm_key_vault_secret.admin_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.admin_username](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [random_password.admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password)                   | resource |

## Modules

| Name               | Source                      | Version |
|--------------------|-----------------------------|---------|
| network            | ./modules/network           | n/a     |
| postgresql\_server | ./modules/postgresql-server | n/a     |

## Inputs

| Name                                       | Description                                                                                                                                  | Type                                                       | Default                                                              | Required |
|--------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------|----------------------------------------------------------------------|:--------:|
| environment                                | Environment for all resources in this module: dev, test, or prod                                                                             | `string`                                                   | n/a                                                                  |   yes    |
| location                                   | Azure region where all resources will be deployed                                                                                            | `string`                                                   | n/a                                                                  |   yes    |
| resource\_group                            | Resource group object containing name and id.                                                                                                | ```object({ name = string })```                            | n/a                                                                  |   yes    |
| resource\_prefix                           | Prefix for all resources in this module                                                                                                      | `string`                                                   | n/a                                                                  |   yes    |
| admin\_password                            | Administrator password for PostgreSQL server. (Otherwise, generated when should\_generate\_admin\_password is true).                         | `string`                                                   | `null`                                                               |    no    |
| admin\_username                            | Administrator username for PostgreSQL server.                                                                                                | `string`                                                   | `"pgadmin"`                                                          |    no    |
| backup\_retention\_days                    | Number of days to retain backups.                                                                                                            | `number`                                                   | `7`                                                                  |    no    |
| databases                                  | Map of databases to create with collation and charset.                                                                                       | ```map(object({ collation = string charset = string }))``` | `null`                                                               |    no    |
| default\_outbound\_access\_enabled         | Whether to enable default outbound internet access for PostgreSQL subnet.                                                                    | `bool`                                                     | `false`                                                              |    no    |
| delegated\_subnet\_id                      | Subnet ID with delegation to Microsoft.DBforPostgreSQL/flexibleServers. (Otherwise, created when should\_create\_delegated\_subnet is true). | `string`                                                   | `null`                                                               |    no    |
| extensions                                 | List of PostgreSQL extensions to enable. Otherwise, ['timescaledb', 'pg\_stat\_statements', 'uuid-ossp', 'hstore'].                          | `list(string)`                                             | ```[ "timescaledb", "pg_stat_statements", "uuid-ossp", "hstore" ]``` |    no    |
| instance                                   | Instance identifier for naming resources: 001, 002, etc                                                                                      | `string`                                                   | `"001"`                                                              |    no    |
| key\_vault                                 | Key Vault object for storing PostgreSQL admin credentials.                                                                                   | ```object({ id = string name = string })```                | `null`                                                               |    no    |
| nat\_gateway                               | NAT gateway object from networking component for managed outbound access.                                                                    | ```object({ id = string name = string })```                | `null`                                                               |    no    |
| network\_security\_group                   | Network security group object to associate with PostgreSQL subnet.                                                                           | ```object({ id = string })```                              | `null`                                                               |    no    |
| postgres\_version                          | PostgreSQL server version.                                                                                                                   | `string`                                                   | `"16"`                                                               |    no    |
| private\_dns\_zone                         | Private DNS zone object for privatelink.postgres.database.azure.com. Otherwise, creates new private DNS zone.                                | ```object({ id = string })```                              | `null`                                                               |    no    |
| should\_create\_delegated\_subnet          | Whether to create delegated subnet for PostgreSQL Flexible Server.                                                                           | `bool`                                                     | `false`                                                              |    no    |
| should\_create\_private\_dns\_zone         | Whether to create private DNS zone for PostgreSQL.                                                                                           | `bool`                                                     | `true`                                                               |    no    |
| should\_enable\_extensions                 | Whether to enable PostgreSQL extensions via azure.extensions.                                                                                | `bool`                                                     | `true`                                                               |    no    |
| should\_enable\_geo\_redundant\_backup     | Whether to enable geo-redundant backups.                                                                                                     | `bool`                                                     | `false`                                                              |    no    |
| should\_enable\_nat\_gateway               | Whether to associate PostgreSQL subnet with a NAT gateway for managed egress.                                                                | `bool`                                                     | `false`                                                              |    no    |
| should\_enable\_timescaledb                | Whether to enable TimescaleDB extension.                                                                                                     | `bool`                                                     | `true`                                                               |    no    |
| should\_generate\_admin\_password          | Whether to auto-generate admin password using random\_password resource.                                                                     | `bool`                                                     | `true`                                                               |    no    |
| should\_store\_credentials\_in\_key\_vault | Whether to store admin credentials in Key Vault as secrets.                                                                                  | `bool`                                                     | `true`                                                               |    no    |
| sku\_name                                  | SKU name for PostgreSQL server.                                                                                                              | `string`                                                   | `"GP_Standard_D2s_v3"`                                               |    no    |
| storage\_mb                                | Storage size in megabytes.                                                                                                                   | `number`                                                   | `32768`                                                              |    no    |
| subnet\_address\_prefixes                  | Address prefixes for the PostgreSQL delegated subnet.                                                                                        | `list(string)`                                             | ```[ "10.0.12.0/24" ]```                                             |    no    |
| virtual\_network                           | Virtual network object for private DNS zone link and delegated subnet creation.                                                              | ```object({ name = string id = string })```                | `null`                                                               |    no    |
| zone                                       | Availability zone for PostgreSQL server deployment.                                                                                          | `string`                                                   | `"1"`                                                                |    no    |

## Outputs

| Name                    | Description                                                |
|-------------------------|------------------------------------------------------------|
| admin\_password\_secret | Key Vault secret reference for admin password.             |
| admin\_username\_secret | Key Vault secret reference for admin username.             |
| connection\_info        | PostgreSQL connection information including credentials.   |
| databases               | Map of created PostgreSQL databases with id and name.      |
| postgres\_subnet        | The delegated subnet for PostgreSQL Flexible Server.       |
| postgresql\_server      | PostgreSQL Flexible Server object with id, name, and fqdn. |
| private\_dns\_zone\_id  | Private DNS zone ID if created.                            |
<!-- END_TF_DOCS -->
