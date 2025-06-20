/*
 * Core Variables - Required
 */

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: e.g., dev, test, prod, etc."
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module."
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z](?:-?[a-zA-Z0-9])*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes. Must start with an alphabetic character."
  }
}

variable "location" {
  type        = string
  description = "Location for all resources in this module."
}

variable "use_existing_resource_group" {
  type        = bool
  description = "Whether to use an existing resource group instead of creating a new one. When true, the component will look up a resource group with the specified or generated name instead of creating it."
  default     = false
}

/*
 * CNCF Cluster General Parameters - Required
 */

variable "should_get_custom_locations_oid" {
  type        = bool
  description = <<-EOF
    Whether to get Custom Locations Object ID using Terraform's azuread provider. (Otherwise, provided by
    'custom_locations_oid' or `az connectedk8s enable-features` for custom-locations on cluster setup if not provided.)
EOF
  default     = true
}

variable "custom_locations_oid" {
  type        = string
  description = <<-EOF
    The object id of the Custom Locations Entra ID application for your tenant.
    If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.

    ```sh
    az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
    ```
EOF
  default     = null
}

/*
 * IoT Ops Parameters - Optional
 */

variable "should_create_anonymous_broker_listener" {
  type        = bool
  description = "Whether to enable an insecure anonymous AIO MQ Broker Listener. Should only be used for dev or test environments."
  default     = false
}

variable "should_enable_opc_ua_simulator" {
  type        = bool
  description = "Whether to deploy the OPC UA Simulator to the cluster"
  default     = true
}

variable "should_enable_otel_collector" {
  type        = bool
  description = "Whether to deploy the OpenTelemetry Collector and Azure Monitor ConfigMap (optionally used)"
  default     = true
}

variable "should_create_azure_functions" {
  type        = bool
  description = "Whether to create Azure Functions for the cluster"
  default     = false
}

/*
 * IoT Asset Endpoints and Assets - Optional
 */

variable "asset_endpoint_profiles" {
  type = list(object({
    name                  = string
    target_address        = string
    endpoint_profile_type = optional(string)
    method                = optional(string)

    should_enable_opc_asset_discovery = optional(bool)
    opc_additional_config_string      = optional(string)
  }))
  description = "List of asset endpoint profiles to create. Otherwise, an empty list."
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
  description = "List of assets to create. Otherwise, an empty list."
  default     = []
}

/*
 * Cluster Server Parameters - Required
 */

variable "cluster_server_ip" {
  type        = string
  description = "The IP Address for the cluster server that the cluster nodes will use to connect."
  default     = null
}

variable "cluster_server_host_machine_username" {
  type        = string
  description = "The username for the cluster server that will be given kubectl access."
  default     = null
}

/*
 * Arc Machine Parameters - Required
 */

variable "arc_machine_name_prefix" {
  type        = string
  description = "The prefix for the arc machine names."
  default     = null
}

variable "arc_machine_count" {
  type        = number
  description = "The number of arc machines that will be in the cluster."
  default     = 2
}

variable "arc_machine_resource_group_name" {
  type        = string
  description = "The name of the Resource Group for the arc machines."
  default     = null
}

/*
 * Resource Group Parameters - Required
 */

variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group that will be created for the resources."
  default     = null
}

variable "resource_group_tags" {
  type        = map(string)
  description = "The tags to add to the resources."
  default     = null
}
