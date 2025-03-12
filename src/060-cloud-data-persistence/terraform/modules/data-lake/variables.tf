variable "container_name" {
  description = "Name of the storage container"
  type        = string
}

variable "container_access_type" {
  description = "The Access Level for the container (blob, container or private)"
  type        = string
}

variable "storage_account_id" {
  description = "ID of the storage account"
  type        = string
}

variable "managed_identity_principal_id" {
  description = "Principal ID of the managed identity to assign roles to"
  type        = string
}

variable "create_file_share" {
  description = "Whether to create a file share"
  type        = bool
}

variable "file_share_name" {
  description = "Name of the file share"
  type        = string
}

variable "file_share_quota_gb" {
  description = "Quota of the file share in GB"
  type        = number
}

variable "data_lake_filesystem_name" {
  description = "Name of the Data Lake Gen2 filesystem"
  type        = string
}