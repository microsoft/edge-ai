/*
 * Core Parameters - Required
 */

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z](?:-?[a-zA-Z0-9])*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes. Must start with an alphabetic character."
  }
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
  default     = "001"
}

/*
 * Core Parameters - Optional
 */

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to create or use. Otherwise, 'rg-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

variable "use_existing_resource_group_for_cloud" {
  type        = bool
  description = "Whether to use an existing resource group for cloud resources with the provided or computed name instead of creating a new one"
  default     = false
}

/*
 * Azure Arc Parameters
 */

variable "arc_cluster_resource_group_name" {
  type        = string
  description = "Name of the resource group for Arc-connected cluster resources. Otherwise, will use the cloud resource group"
  default     = null
}

variable "use_existing_resource_group_for_arc_cluster" {
  type        = bool
  description = "Whether to use an existing resource group for Arc-connected cluster resources with the provided or computed name instead of creating a new one"
  default     = true
}

/*
 * Azure Local Cluster Parameters
 */
variable "custom_locations_oid" {
  type        = string
  description = "Resource ID of the custom location for the Azure Stack HCI cluster"
  default     = null
}

variable "logical_network_name" {
  type        = string
  description = "Name of the logical network for the Azure Local Kubernetes cluster"
  default     = null
}

variable "logical_network_resource_group_name" {
  type        = string
  description = "Name of the resource group containing the logical network for the Azure Local Kubernetes cluster"
  default     = null
}

variable "azure_local_control_plane_count" {
  type        = number
  description = "Number of control plane nodes for Azure Local cluster"
  default     = 1
}

variable "azure_local_node_pool_count" {
  type        = number
  description = "Number of worker nodes in the default node pool for Azure Local cluster"
  default     = 1
}

variable "azure_local_control_plane_vm_size" {
  type        = string
  description = "VM size for control plane nodes in Azure Local cluster"
  default     = "Standard_A4_v2"
}

variable "azure_local_node_pool_vm_size" {
  type        = string
  description = "VM size for worker nodes in Azure Local cluster"
  default     = "Standard_D8s_v3"
}

variable "azure_local_pod_cidr" {
  type        = string
  description = "CIDR range for Kubernetes pods in Azure Local cluster"
  default     = "10.244.0.0/16"
}

variable "azure_local_aad_profile" {
  type = object({
    admin_group_object_ids = optional(list(string), [])
    enable_azure_rbac      = bool
    tenant_id              = optional(string)
  })
  description = "Azure Active Directory profile configuration for the Azure Local Kubernetes cluster"
  default = {
    admin_group_object_ids = []
    enable_azure_rbac      = true
    tenant_id              = null
  }
}

/*
 * Cloud Resource Parameters
 */

variable "should_create_azure_functions" {
  type        = bool
  description = "Whether to create Azure Functions resources for downstream messaging integrations"
  default     = false
}

variable "should_enable_key_vault_public_network_access" {
  type        = bool
  description = "Whether to enable public network access for the Key Vault"
  default     = true
}

variable "should_enable_storage_public_network_access" {
  type        = bool
  description = "Whether to enable public network access for the storage account"
  default     = true
}

variable "storage_account_is_hns_enabled" {
  type        = bool
  description = "Whether to enable hierarchical namespace on the storage account"
  default     = true
}

variable "should_create_data_lake" {
  type        = bool
  description = "Whether to create a Data Lake Gen2 storage account instead of a standard storage account"
  default     = true
}

/*
 * Azure IoT Operations Parameters
 */

variable "aio_features" {
  description = "AIO features with mode ('Stable', 'Preview', 'Disabled') and settings ('Enabled', 'Disabled')"
  type = map(object({
    mode     = optional(string)
    settings = optional(map(string))
  }))
  default = null

  validation {
    condition = var.aio_features == null ? true : alltrue([
      for feature_name, feature in coalesce(var.aio_features, {}) :
      try(
        feature.mode == null ? true : contains(["Stable", "Preview", "Disabled"], feature.mode),
        true
      )
    ])
    error_message = "Feature mode must be one of: 'Stable', 'Preview', or 'Disabled'."
  }

  validation {
    condition = var.aio_features == null ? true : alltrue([
      for feature_name, feature in coalesce(var.aio_features, {}) :
      try(
        feature.settings == null ? true : alltrue([
          for setting_name, setting_value in feature.settings :
          contains(["Enabled", "Disabled"], setting_value)
        ]),
        true
      )
    ])
    error_message = "Feature settings values must be either 'Enabled' or 'Disabled'."
  }
}

variable "asset_endpoint_profiles" {
  type = list(object({
    name                  = string
    target_address        = string
    endpoint_profile_type = optional(string)
    method                = optional(string)

    should_enable_opc_asset_discovery = optional(bool)
    opc_additional_config_string      = optional(string)
  }))
  description = "List of asset endpoint profiles to create; otherwise, an empty list"
  default     = []
}

variable "assets" {
  type = list(object({
    asset_endpoint_profile_ref = string
    datasets = optional(list(object({
      data_points = list(object({
        data_point_configuration = optional(string)
        data_source              = string
        name                     = string
        observability_mode       = optional(string)
      }))
      name = string
    })), [])
    default_datasets_configuration = optional(string)
    description                    = optional(string)
    display_name                   = optional(string)
    documentation_uri              = optional(string)
    enabled                        = optional(bool)
    hardware_revision              = optional(string)
    manufacturer                   = optional(string)
    manufacturer_uri               = optional(string)
    model                          = optional(string)
    name                           = string
    product_code                   = optional(string)
    serial_number                  = optional(string)
    software_revision              = optional(string)
  }))
  description = "List of assets to create; otherwise, an empty list"
  default     = []
}

variable "should_create_anonymous_broker_listener" {
  type        = bool
  description = "Whether to enable an insecure anonymous AIO MQ broker listener; use only for dev or test environments"
  default     = false
}

variable "should_deploy_resource_sync_rules" {
  type        = bool
  description = "Whether to deploy resource sync rules"
  default     = true
}

variable "should_enable_opc_ua_simulator" {
  type        = bool
  description = "Whether to deploy the OPC UA simulator to the cluster"
  default     = false
}





