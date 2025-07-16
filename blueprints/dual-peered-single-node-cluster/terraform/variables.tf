variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod."
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

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc..."
  default     = "001"
}

/*
 * Cluster A Configuration
 */

variable "use_existing_resource_group_a" {
  type        = bool
  description = "Whether to use an existing resource group for Cluster A instead of creating a new one. When true, the component will look up a resource group with the specified or generated name instead of creating it."
  default     = false
}

variable "resource_group_name_a" {
  type        = string
  description = "The name for the Cluster A resource group. If not provided, a default name will be generated using resource_prefix, environment, and instance."
  default     = null
}

variable "cluster_a_virtual_network_config" {
  type = object({
    address_space         = string
    subnet_address_prefix = string
  })
  description = "Configuration for Cluster A virtual network including address space and subnet prefix."
  default = {
    address_space         = "10.1.0.0/16"
    subnet_address_prefix = "10.1.1.0/24"
  }
  validation {
    condition     = can(cidrhost(var.cluster_a_virtual_network_config.address_space, 0)) && can(cidrhost(var.cluster_a_virtual_network_config.subnet_address_prefix, 0))
    error_message = "Both address_space and subnet_address_prefix must be valid CIDR blocks."
  }
}

/*
 * Cluster B Configuration
 */

variable "use_existing_resource_group_b" {
  type        = bool
  description = "Whether to use an existing resource group for Cluster B instead of creating a new one. When true, the component will look up a resource group with the specified or generated name instead of creating it."
  default     = false
}

variable "resource_group_name_b" {
  type        = string
  description = "The name for the Cluster B resource group. If not provided, a default name will be generated using resource_prefix, environment, and instance."
  default     = null
}

variable "cluster_b_virtual_network_config" {
  type = object({
    address_space         = string
    subnet_address_prefix = string
  })
  description = "Configuration for Cluster B virtual network including address space and subnet prefix."
  default = {
    address_space         = "10.2.0.0/16"
    subnet_address_prefix = "10.2.1.0/24"
  }
  validation {
    condition     = can(cidrhost(var.cluster_b_virtual_network_config.address_space, 0)) && can(cidrhost(var.cluster_b_virtual_network_config.subnet_address_prefix, 0))
    error_message = "Both address_space and subnet_address_prefix must be valid CIDR blocks."
  }
}

/*
 * Shared Configuration
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

variable "should_create_anonymous_broker_listener" {
  type        = bool
  description = "Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)"
  default     = false
}

variable "should_create_aks" {
  type        = bool
  description = "Should create Azure Kubernetes Service. Default is false."
  default     = false
}

variable "should_create_acr_private_endpoint" {
  type        = bool
  description = "Should create a private endpoint for the Azure Container Registry. Default is false."
  default     = false
}

variable "aio_features" {
  description = "AIO Instance features with mode ('Stable', 'Preview', 'Disabled') and settings ('Enabled', 'Disabled')."
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

variable "should_deploy_resource_sync_rules" {
  type        = bool
  default     = false
  description = "Deploys resource sync rules if set to true."
}

variable "should_enable_opc_ua_simulator" {
  type        = bool
  description = "Should create an OPC UA Simulator. Default is false."
  default     = false
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

variable "should_create_azure_functions" {
  type        = bool
  description = "Whether to create Azure Functions for the clusters."
  default     = false
}

/*
 * Script Deployment Configuration
 */

variable "should_deploy_custom_scripts" {
  type        = bool
  description = "Whether to deploy the custom scripts (server-central.sh and client-technology.sh) to the VMs."
  default     = false
}

variable "should_deploy_server_central_script" {
  type        = bool
  description = "Whether to deploy the server-central.sh script to Cluster A VM."
  default     = false
}

variable "should_deploy_client_technology_script" {
  type        = bool
  description = "Whether to deploy the client-technology.sh script to Cluster B VM."
  default     = false
}

variable "should_create_certificates" {
  type        = bool
  description = "Whether to generate certificates using the certs.sh script before deployment."
  default     = true
}

variable "use_terraform_certificates" {
  type        = bool
  description = "Use Terraform TLS provider instead of Step CLI for certificate generation. Only applies when should_create_certificates is true."
  default     = false
}
