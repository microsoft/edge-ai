variable "data_lake_blob_container_name" {
  description = "The name of the Blob Container for the data lake."
  type        = string
}

variable "container_access_type" {
  description = "The Access Level for the container (blob, container or private)"
  type        = string
}

variable "data_lake_data_owner_principal_id" {
  description = "The Principal ID that will be assigned the 'Storage Blob Data Owner' role at the Storage Account scope. (Otherwise, uses the current logged in user)"
  type        = string
}

variable "data_lake_data_contributor_principal_id" {
  type        = string
  description = "The Principal ID that will be assigned the 'Storage Blob Data Contributor' role at the Storage Account scope"
}

variable "should_create_data_lake_file_share" {
  description = "Whether to create a file share"
  type        = bool
}

variable "file_share_name" {
  type        = string
  description = "Name of the file share to create"
}

variable "file_share_quota_gb" {
  type        = number
  description = "Maximum size of the file share in GB"
}

variable "data_lake_filesystem_name" {
  type        = string
  description = "Name of the Data Lake Gen2 filesystem to create"
}
