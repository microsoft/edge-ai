# Basic Resource Variables
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

# Storage Account Variables
variable "storage_account_tier" {
  description = "Defines the Tier to use for this storage account (Standard or Premium)"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication" {
  description = "Defines the type of replication to use for this storage account (LRS, GRS, RAGRS, ZRS)"
  type        = string
  default     = "LRS"
}

variable "storage_account_kind" {
  description = "Defines the Kind of account (BlobStorage, BlockBlobStorage, FileStorage, Storage or StorageV2)"
  type        = string
  default     = "StorageV2"
}

# Blob Storage Variables
variable "blob_soft_delete_retention_days" {
  description = "Number of days to retain deleted blobs"
  type        = number
  default     = 7
}

variable "container_soft_delete_retention_days" {
  description = "Number of days to retain deleted containers"
  type        = number
  default     = 7
}

variable "container_name" {
  description = "Name of the container to create"
  type        = string
  default     = "data"
}

variable "container_access_type" {
  description = "The Access Level for the container (blob, container or private)"
  type        = string
  default     = "private"
}

# File Share Variables
variable "create_file_share" {
  description = "Whether to create a file share"
  type        = bool
  default     = false
}

variable "file_share_name" {
  description = "Name of the file share to create"
  type        = string
  default     = "fileshare"
}

variable "file_share_quota_gb" {
  description = "Maximum size of the file share in GB"
  type        = number
  default     = 5
}

# Data Lake Variables
variable "data_lake_filesystem_name" {
  description = "Name of the Data Lake Gen2 filesystem to create"
  type        = string
  default     = "datalake"
}

# Identity Variables
variable "managed_identity_principal_id" {
  description = "Principal ID of a managed identity that should be granted Storage Blob Data Contributor access"
  type        = string
  default     = ""
}
