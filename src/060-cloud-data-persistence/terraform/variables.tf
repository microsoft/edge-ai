/*
 * Storage Account
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
 * Private Endpoint for Storage Account
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
 * Blob Container Configuration
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

variable "data_lake_blob_container_name" {
  description = "The name of the Blob Container for the data lake."
  type        = string
  default     = "data"
}

variable "container_access_type" {
  description = "The Access Level for the container (blob, container or private)"
  type        = string
  default     = "private"
}

variable "should_create_data_lake" {
  description = "Whether or not to create the data lake which includes a Blob Container and Data Lake Filesystem."
  type        = bool
  default     = true
}

/*
 * Data Lake
 */

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
 * File Share
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

# Microsoft Fabric EventStream Variables
variable "should_create_fabric_eventstream" {
  description = "Whether to create a new Fabric EventStream"
  type        = bool
  default     = false

  validation {
    condition     = var.should_create_fabric_eventstream ? (var.should_create_fabric_lakehouse && var.eventhub_endpoint != null) : true
    error_message = "'should_create_fabric_eventstream' requires both 'should_create_fabric_lakehouse=true' and 'eventhub_endpoint' to be provided."
  }
}

variable "eventstream_description" {
  description = "The description of the Microsoft Fabric event stream"
  type        = string
  default     = "Event Stream for real-time ingestion of Edge device data"
}

variable "eventhub_endpoint" {
  description = "The endpoint of the Eventhub to connect to the EventStream"
  type        = string
  default     = null
}

# Microsoft Fabric Workspace Variables

variable "workspace_description" {
  description = "The description of the Microsoft Fabric workspace"
  type        = string
  default     = "Microsoft Fabric workspace for the Edge AI Accelerator solution"
}

variable "lakehouse_description" {
  description = "The description of the Microsoft Fabric lakehouse"
  type        = string
  default     = "Lakehouse for storing and analyzing data from Edge devices"
}

# Microsoft Fabric Options
variable "should_create_fabric_workspace" {
  description = "Whether to create a new Microsoft Fabric workspace or use an existing one"
  type        = bool
  default     = false
}

variable "existing_fabric_workspace_id" {
  description = "The ID of an existing Microsoft Fabric workspace to use (if should_create_fabric_workspace=false)"
  type        = string
  default     = null
}

variable "capacity_id" {
  description = "ID of the Microsoft Fabric capacity to use. Leave empty to use free tier."
  type        = string
  default     = null
}

variable "should_create_fabric_lakehouse" {
  type        = bool
  description = "Whether to create a Microsoft Fabric lakehouse"
  default     = false
  validation {
    condition     = var.should_create_fabric_lakehouse ? anytrue([var.should_create_fabric_workspace, var.existing_fabric_workspace_id != null]) : true
    error_message = "To create a lakehouse, you must either create a workspace or provide an existing workspace ID."
  }
}

# Fabric capacity variables
variable "should_create_fabric_capacity" {
  description = "Whether to create a new Fabric capacity or use an existing one"
  type        = bool
  default     = false
}

variable "fabric_capacity_id" {
  description = "The ID of an existing Fabric capacity to use (required when create_fabric_capacity=false)"
  type        = string
  default     = null
}

variable "fabric_capacity_sku" {
  description = "The SKU name for the Fabric capacity"
  type        = string
  default     = "F2"
}

variable "fabric_capacity_admins" {
  description = "List of AAD object IDs for Fabric capacity administrators"
  type        = list(string)
  default     = []
}