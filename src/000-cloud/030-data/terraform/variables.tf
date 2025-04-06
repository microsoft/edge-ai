/*
 * Schema Registry
 */

variable "should_create_schema_registry" {
  description = "Whether to crate the Schema Registry resources."
  type        = bool
  default     = true
}

/*
 * Storage Account - Optional
 */

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

/*
 * Private Endpoint for Storage Account - Optional
 */

variable "should_enable_private_endpoint" {
  description = "Whether to create a private endpoint for the storage account"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "ID of the subnet to deploy the private endpoint"
  type        = string
  default     = null
}

/*
 * Blob Container - Optional
 */

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

variable "container_access_type" {
  description = "The Access Level for the container (blob, container or private)"
  type        = string
  default     = "private"
}

/*
 * Data Lake - Optional
 */

variable "should_create_data_lake" {
  description = "Whether or not to create the data lake which includes a Blob Container and Data Lake Filesystem."
  type        = bool
  default     = true
}

variable "data_lake_blob_container_name" {
  description = "The name of the Blob Container for the data lake."
  type        = string
  default     = "data"
}

variable "data_lake_filesystem_name" {
  description = "Name of the Data Lake Gen2 filesystem to create"
  type        = string
  default     = "datalake"
}

variable "data_lake_data_owner_principal_id" {
  description = "The Principal ID that will be assigned the 'Storage Blob Data Owner' role at the Storage Account scope. (Otherwise, uses the current logged in user)"
  type        = string
  default     = null
}

variable "data_lake_data_contributor_principal_id" {
  description = "Principal ID of a managed identity that should be granted Storage Blob Data Contributor access"
  type        = string
  default     = null
}

/*
 * File Share - Optional
 */

variable "should_create_data_lake_file_share" {
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
