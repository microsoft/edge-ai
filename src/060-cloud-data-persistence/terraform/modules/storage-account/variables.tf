variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

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

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "instance" {
  description = "Instance identifier to distinguish between multiple instances"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix to add to all resources"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet to deploy the private endpoint"
  type        = string
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for the storage account"
  type        = bool
}