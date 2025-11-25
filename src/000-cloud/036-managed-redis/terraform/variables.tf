/*
 * Core Variables - Required
 */

variable "environment" {
  description = "Environment for all resources in this module: dev, test, or prod"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "instance" {
  description = "Instance identifier for naming resources: 001, 002, etc"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.instance))
    error_message = "Instance must contain only lowercase letters and numbers."
  }
}

variable "location" {
  description = "Location for all resources in this module"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for all resources in this module"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.resource_prefix))
    error_message = "Resource prefix must contain only lowercase letters, numbers, and hyphens."
  }
}

/*
 * Redis Configuration - Optional
 */

variable "access_keys_authentication_enabled" {
  description = "Whether to enable access key authentication. Set to false for Entra ID only (recommended for production)"
  type        = bool
  default     = false
}

variable "clustering_policy" {
  description = "Redis clustering policy. Options: OSSCluster (default, Redis OSS), EnterpriseCluster (Redis Enterprise)"
  type        = string
  default     = "OSSCluster"

  validation {
    condition     = contains(["OSSCluster", "EnterpriseCluster"], var.clustering_policy)
    error_message = "Clustering policy must be 'OSSCluster' or 'EnterpriseCluster'."
  }
}

variable "customer_managed_key" {
  description = "Customer-managed key configuration for encryption at rest"
  type = object({
    key_vault_key_id          = string
    user_assigned_identity_id = string
  })
  default = null
}

variable "should_deploy_redis" {
  description = "Whether to deploy Azure Managed Redis cache"
  type        = bool
  default     = true
}

variable "should_enable_high_availability" {
  description = "Whether to enable high availability mode. Recommended for production, can be disabled for dev/test cost savings"
  type        = bool
  default     = true
}

variable "sku_name" {
  description = "Azure Managed Redis SKU name. Format: {Family}_{Size} where Family is Balanced, Memory, Compute, or Flash"
  type        = string
  default     = "Balanced_B10"

  validation {
    condition     = can(regex("^(Balanced|Memory|Compute|Flash)_(B|M|X|F)[0-9]+$", var.sku_name))
    error_message = "SKU name must follow format: {Family}_{Size} (e.g., Balanced_B10, Memory_M60, Compute_X24, Flash_F480)."
  }
}

/*
 * Private Endpoint Configuration - Optional
 */

variable "should_create_private_dns_zone" {
  description = "Whether to create a new private DNS zone. Set to false if using existing zone"
  type        = bool
  default     = true
}

variable "should_enable_private_endpoint" {
  description = "Whether to create a private endpoint for the Redis cache"
  type        = bool
  default     = false
}
