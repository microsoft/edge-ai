variable "resource_group" {
  description = "Resource group object containing name and id."
  type = object({
    name = string
  })
}

variable "location" {
  description = "Azure region for PostgreSQL server deployment."
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name: dev, test, or prod."
  type        = string
}

variable "instance" {
  description = "Instance identifier for resource uniqueness."
  type        = string
}

variable "postgres_version" {
  description = "PostgreSQL server version."
  type        = string
}

variable "sku_name" {
  description = "SKU name for PostgreSQL server."
  type        = string
}

variable "storage_mb" {
  description = "Storage size in megabytes."
  type        = number
}

variable "delegated_subnet_id" {
  description = "Subnet ID with delegation to Microsoft.DBforPostgreSQL/flexibleServers."
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for privatelink.postgres.database.azure.com."
  type        = string
}

variable "admin_username" {
  description = "Administrator username for PostgreSQL server."
  type        = string
}

variable "admin_password" {
  description = "Administrator password for PostgreSQL server."
  type        = string
  sensitive   = true
}

variable "databases" {
  description = "Map of databases to create with collation and charset."
  type = map(object({
    collation = string
    charset   = string
  }))
}

variable "zone" {
  description = "Availability zone for PostgreSQL server deployment."
  type        = string
}

variable "should_enable_timescaledb" {
  description = "Whether to enable TimescaleDB extension."
  type        = bool
}

variable "should_enable_extensions" {
  description = "Whether to enable PostgreSQL extensions via azure.extensions."
  type        = bool
}

variable "extensions" {
  description = "List of PostgreSQL extensions to enable."
  type        = list(string)
}

variable "backup_retention_days" {
  description = "Number of days to retain backups."
  type        = number
}

variable "should_enable_geo_redundant_backup" {
  description = "Whether to enable geo-redundant backups."
  type        = bool
}
