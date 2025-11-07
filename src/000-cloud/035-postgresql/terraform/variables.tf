/*
 * PostgreSQL Core Variables - Required
 */

variable "admin_password" {
  description = "Administrator password for PostgreSQL server. (Otherwise, generated when should_generate_admin_password is true)."
  type        = string
  sensitive   = true
  default     = null
}

variable "admin_username" {
  description = "Administrator username for PostgreSQL server."
  type        = string
  default     = "pgadmin"
}

variable "should_generate_admin_password" {
  description = "Whether to auto-generate admin password using random_password resource."
  type        = bool
  default     = true
}

variable "should_store_credentials_in_key_vault" {
  description = "Whether to store admin credentials in Key Vault as secrets."
  type        = bool
  default     = true
}

variable "delegated_subnet_id" {
  description = "Subnet ID with delegation to Microsoft.DBforPostgreSQL/flexibleServers. (Otherwise, created when should_create_delegated_subnet is true)."
  type        = string
  default     = null
}

/*
 * PostgreSQL Configuration - Optional
 */

variable "backup_retention_days" {
  description = "Number of days to retain backups."
  type        = number
  default     = 7
}

variable "databases" {
  description = "Map of databases to create with collation and charset."
  type = map(object({
    collation = string
    charset   = string
  }))
  default = null
}

variable "extensions" {
  description = "List of PostgreSQL extensions to enable. Otherwise, ['timescaledb', 'pg_stat_statements', 'uuid-ossp']."
  type        = list(string)
  default     = ["timescaledb", "pg_stat_statements", "uuid-ossp"]
}

variable "postgres_version" {
  description = "PostgreSQL server version."
  type        = string
  default     = "16"
}

variable "should_create_private_dns_zone" {
  description = "Whether to create private DNS zone for PostgreSQL."
  type        = bool
  default     = true
}

variable "should_enable_geo_redundant_backup" {
  description = "Whether to enable geo-redundant backups."
  type        = bool
  default     = false
}

variable "should_enable_extensions" {
  description = "Whether to enable PostgreSQL extensions via azure.extensions."
  type        = bool
  default     = true
}

variable "should_enable_timescaledb" {
  description = "Whether to enable TimescaleDB extension."
  type        = bool
  default     = true
}

variable "sku_name" {
  description = "SKU name for PostgreSQL server."
  type        = string
  default     = "GP_Standard_D2s_v3"
}

variable "zone" {
  description = "Availability zone for PostgreSQL server deployment."
  type        = string
  default     = "1"
}

variable "storage_mb" {
  description = "Storage size in megabytes."
  type        = number
  default     = 32768
}

/*
 * Networking Configuration - Optional
 */

variable "should_create_delegated_subnet" {
  description = "Whether to create delegated subnet for PostgreSQL Flexible Server."
  type        = bool
  default     = false
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the PostgreSQL delegated subnet."
  type        = list(string)
  default     = ["10.0.12.0/24"]
}

variable "default_outbound_access_enabled" {
  description = "Whether to enable default outbound internet access for PostgreSQL subnet."
  type        = bool
  default     = false
}

variable "should_enable_nat_gateway" {
  description = "Whether to associate PostgreSQL subnet with a NAT gateway for managed egress."
  type        = bool
  default     = false
}
