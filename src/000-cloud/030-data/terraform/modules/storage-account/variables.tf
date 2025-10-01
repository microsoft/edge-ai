variable "account_tier" {
  description = "Defines the Tier to use for this storage account (Standard or Premium)"
  type        = string
}

variable "account_replication_type" {
  description = "Defines the type of replication to use for this storage account (LRS, GRS, RAGRS, ZRS)"
  type        = string
}

variable "account_kind" {
  description = "Defines the Kind of account (BlobStorage, BlockBlobStorage, FileStorage, Storage or StorageV2)"
  type        = string
}

variable "blob_soft_delete_retention_days" {
  description = "Number of days to retain deleted blobs"
  type        = number
}

variable "container_soft_delete_retention_days" {
  description = "Number of days to retain deleted containers"
  type        = number
}

variable "is_hns_enabled" {
  description = "Whether to enable Hierarchical Namespace (HNS) for Azure Data Lake Storage Gen2. Note: Azure ML workspaces do not support HNS-enabled storage accounts."
  type        = bool
}

variable "should_enable_public_network_access" {
  description = "Whether to enable public network access for the storage account"
  type        = bool
}

/*
 * Private Endpoint
 */

variable "should_enable_private_endpoint" {
  description = "Whether to create a private endpoint for the storage account"
  type        = bool
}

variable "private_endpoint_subnet_id" {
  description = "ID of the subnet to deploy the private endpoint"
  type        = string
}

variable "virtual_network_id" {
  description = "The ID of the virtual network to link to the private DNS zones"
  type        = string
}
