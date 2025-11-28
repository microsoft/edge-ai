# PostgreSQL Flexible Server Component

Deploys Azure PostgreSQL Flexible Server with TimescaleDB extension support for time-series data workloads.

## Features

* PostgreSQL 16 server with flexible SKU options
* TimescaleDB extension for time-series data
* Private networking with delegated subnet
* Private DNS zone integration
* Geo-redundant backup support
* Multiple database creation

## Usage Scenarios

* Time-series data storage for IoT workloads
* Application database backend with private connectivity
* Development and production PostgreSQL instances

## Implementation

See `terraform/README.md` for complete Terraform documentation including variables, outputs, and examples.

## Dependencies

* Resource Group (000-resource-group)
* Networking (050-networking) - requires delegated subnet for PostgreSQL
* Security Identity (010-security-identity) - for Key Vault password storage

## Private Networking

This component requires:

* A subnet delegated to `Microsoft.DBforPostgreSQL/flexibleServers`
* Private DNS zone `privatelink.postgres.database.azure.com` (auto-created or provided)
* Virtual network for DNS zone linking
