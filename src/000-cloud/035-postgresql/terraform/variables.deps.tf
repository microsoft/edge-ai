/*
 * Component Dependencies - Required
 */

variable "resource_group" {
  description = "Resource group object containing name and id."
  type = object({
    name = string
  })
}

/*
 * Component Dependencies - Optional
 */

variable "private_dns_zone" {
  description = "Private DNS zone object for privatelink.postgres.database.azure.com. Otherwise, creates new private DNS zone."
  type = object({
    id = string
  })
  default = null
}

variable "virtual_network" {
  description = "Virtual network object for private DNS zone link and delegated subnet creation."
  type = object({
    name = string
    id   = string
  })
  default = null
}

variable "network_security_group" {
  description = "Network security group object to associate with PostgreSQL subnet."
  type = object({
    id = string
  })
  default = null
}

variable "nat_gateway" {
  description = "NAT gateway object from networking component for managed outbound access."
  type = object({
    id   = string
    name = string
  })
  default = null
}

variable "key_vault" {
  description = "Key Vault object for storing PostgreSQL admin credentials."
  type = object({
    id   = string
    name = string
  })
  default = null
}
