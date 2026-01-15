variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "resource_prefix" {
  type = string
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z](?:-?[a-zA-Z0-9])*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes. Must start with an alphabetic character."
  }
  description = "Prefix for all resources in this module"
}

variable "location" {
  type        = string
  description = "Azure region where all resources will be deployed"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
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

variable "cluster_a_subnet_address_prefixes_acr" {
  type        = list(string)
  description = "Address prefixes for the ACR subnet."
  default     = ["10.1.2.0/24"]
}

variable "cluster_a_subnet_address_prefixes_aks" {
  type        = list(string)
  description = "Address prefixes for the AKS subnet."
  default     = ["10.1.3.0/24"]
}

variable "cluster_a_subnet_address_prefixes_aks_pod" {
  type        = list(string)
  description = "Address prefixes for the AKS pod subnet."
  default     = ["10.1.4.0/24"]
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

variable "cluster_b_subnet_address_prefixes_acr" {
  type        = list(string)
  description = "Address prefixes for the ACR subnet."
  default     = ["10.2.2.0/24"]
}

variable "cluster_b_subnet_address_prefixes_aks" {
  type        = list(string)
  description = "Address prefixes for the AKS subnet."
  default     = ["10.2.3.0/24"]
}

variable "cluster_b_subnet_address_prefixes_aks_pod" {
  type        = list(string)
  description = "Address prefixes for the AKS pod subnet."
  default     = ["10.2.4.0/24"]
}
/*
 * Shared Configuration
 */
variable "aio_namespace" {
  type        = string
  description = "Azure IoT Operations namespace"
  default     = "azure-iot-operations"
}

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
  description = "Whether to enable an insecure anonymous AIO MQ Broker Listener. Should only be used for dev or test environments"
  default     = false
}

variable "should_create_aks" {
  type        = bool
  description = "Should create Azure Kubernetes Service. Default is false."
  default     = false
}

/*
 * AKS Cluster Configuration - Cluster A
 */

variable "cluster_a_node_count" {
  type        = number
  description = "Number of nodes for the agent pool in the AKS cluster for Cluster A."
  default     = 1
}

variable "cluster_a_node_vm_size" {
  type        = string
  description = "VM size for the agent pool in the AKS cluster for Cluster A. Default is Standard_D8ds_v5."
  default     = "Standard_D8ds_v5"
}

variable "cluster_a_enable_auto_scaling" {
  type        = bool
  description = "Should enable auto-scaler for the default node pool for Cluster A."
  default     = false
}

variable "cluster_a_min_count" {
  type        = number
  description = "The minimum number of nodes which should exist in the default node pool for Cluster A. Valid values are between 0 and 1000."
  default     = null
}

variable "cluster_a_max_count" {
  type        = number
  description = "The maximum number of nodes which should exist in the default node pool for Cluster A. Valid values are between 0 and 1000."
  default     = null
}

variable "cluster_a_dns_prefix" {
  type        = string
  default     = null
  description = "DNS prefix for the AKS cluster for Cluster A. This is used to create a unique DNS name for the cluster. If not provided, a default value will be generated."
}

variable "cluster_a_node_pools" {
  type = map(object({
    node_count                  = number
    vm_size                     = string
    subnet_address_prefixes     = list(string)
    pod_subnet_address_prefixes = list(string)
    node_taints                 = optional(list(string), [])
    enable_auto_scaling         = optional(bool, false)
    min_count                   = optional(number, null)
    max_count                   = optional(number, null)
  }))
  description = "Additional node pools for the AKS cluster for Cluster A. Map key is used as the node pool name."
  default     = {}
}

/*
 * AKS Cluster Configuration - Cluster B
 */

variable "cluster_b_node_count" {
  type        = number
  description = "Number of nodes for the agent pool in the AKS cluster for Cluster B."
  default     = 1
}

variable "cluster_b_node_vm_size" {
  type        = string
  description = "VM size for the agent pool in the AKS cluster for Cluster B. Default is Standard_D8ds_v5."
  default     = "Standard_D8ds_v5"
}

variable "cluster_b_enable_auto_scaling" {
  type        = bool
  description = "Should enable auto-scaler for the default node pool for Cluster B."
  default     = false
}

variable "cluster_b_min_count" {
  type        = number
  description = "The minimum number of nodes which should exist in the default node pool for Cluster B. Valid values are between 0 and 1000."
  default     = null
}

variable "cluster_b_max_count" {
  type        = number
  description = "The maximum number of nodes which should exist in the default node pool for Cluster B. Valid values are between 0 and 1000."
  default     = null
}

variable "cluster_b_dns_prefix" {
  type        = string
  default     = null
  description = "DNS prefix for the AKS cluster for Cluster B. This is used to create a unique DNS name for the cluster. If not provided, a default value will be generated."
}

variable "cluster_b_node_pools" {
  type = map(object({
    node_count                  = number
    vm_size                     = string
    subnet_address_prefixes     = list(string)
    pod_subnet_address_prefixes = list(string)
    node_taints                 = optional(list(string), [])
    enable_auto_scaling         = optional(bool, false)
    min_count                   = optional(number, null)
    max_count                   = optional(number, null)
  }))
  description = "Additional node pools for the AKS cluster for Cluster B. Map key is used as the node pool name."
  default     = {}
}

variable "should_enable_private_endpoints" {
  type        = bool
  description = "Whether to enable private endpoints for Key Vault and Storage Account for both clusters"
  default     = false
}

/*
 * Outbound Access Configuration
 */

variable "should_enable_managed_outbound_access" {
  type        = bool
  description = "Whether to enable managed outbound egress via NAT gateway instead of platform default internet access"
  default     = true
}

variable "nat_gateway_idle_timeout_minutes" {
  type        = number
  description = "Idle timeout in minutes for NAT gateway connections"
  default     = 4
  validation {
    condition     = var.nat_gateway_idle_timeout_minutes >= 4 && var.nat_gateway_idle_timeout_minutes <= 240
    error_message = "Idle timeout must be between 4 and 240 minutes"
  }
}

variable "nat_gateway_public_ip_count" {
  type        = number
  description = "Number of public IP addresses to associate with the NAT gateway (example: 2)"
  default     = 1
  validation {
    condition     = var.nat_gateway_public_ip_count >= 1 && var.nat_gateway_public_ip_count <= 16
    error_message = "Public IP count must be between 1 and 16"
  }
}

variable "nat_gateway_zones" {
  type        = list(string)
  description = "Availability zones for NAT gateway resources when zone-redundancy is required (example: ['1','2'])"
  default     = []
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
  description = "Deploys resource sync rules if set to true"
  default     = false
}

variable "should_enable_opc_ua_simulator" {
  type        = bool
  description = "Whether to deploy the OPC UA Simulator to the cluster. Default is false"
  default     = false
}

variable "namespaced_devices" {
  type = list(object({
    name    = string
    enabled = optional(bool, true)
    endpoints = object({
      outbound = optional(object({
        assigned = object({})
      }), { assigned = {} })
      inbound = map(object({
        endpoint_type           = string
        address                 = string
        version                 = optional(string, null)
        additionalConfiguration = optional(string)
        authentication = object({
          method = string
          usernamePasswordCredentials = optional(object({
            usernameSecretName = string
            passwordSecretName = string
          }))
          x509Credentials = optional(object({
            certificateSecretName = string
          }))
        })
        trustSettings = optional(object({
          trustList = string
        }))
      }))
    })
  }))
  description = "List of namespaced devices to create. Otherwise, an empty list."
  default     = []
}

variable "namespaced_assets" {
  type = list(object({
    name         = string
    display_name = optional(string)
    device_ref = optional(object({
      device_name   = string
      endpoint_name = string
    }))
    asset_endpoint_profile_ref     = optional(string)
    default_datasets_configuration = optional(string)
    default_streams_configuration  = optional(string)
    default_events_configuration   = optional(string)
    description                    = optional(string)
    documentation_uri              = optional(string)
    enabled                        = optional(bool, true)
    hardware_revision              = optional(string)
    manufacturer                   = optional(string)
    manufacturer_uri               = optional(string)
    model                          = optional(string)
    product_code                   = optional(string)
    serial_number                  = optional(string)
    software_revision              = optional(string)
    attributes                     = optional(map(string), {})
    datasets = optional(list(object({
      name = string
      data_points = list(object({
        data_point_configuration  = optional(string)
        data_source               = string
        name                      = string
        observability_mode        = optional(string)
        rest_sampling_interval_ms = optional(number)
        rest_mqtt_topic           = optional(string)
        rest_include_state_store  = optional(bool)
        rest_state_store_key      = optional(string)
      }))
      dataset_configuration = optional(string)
      data_source           = optional(string)
      destinations = optional(list(object({
        target = string
        configuration = object({
          topic  = optional(string)
          retain = optional(string)
          qos    = optional(string)
        })
      })), [])
      type_ref = optional(string)
    })), [])
    streams = optional(list(object({
      name                 = string
      stream_configuration = optional(string)
      type_ref             = optional(string)
      destinations = optional(list(object({
        target = string
        configuration = object({
          topic  = optional(string)
          retain = optional(string)
          qos    = optional(string)
        })
      })), [])
    })), [])
    event_groups = optional(list(object({
      name                      = string
      data_source               = optional(string)
      event_group_configuration = optional(string)
      type_ref                  = optional(string)
      default_destinations = optional(list(object({
        target = string
        configuration = object({
          topic  = optional(string)
          retain = optional(string)
          qos    = optional(string)
        })
      })), [])
      events = list(object({
        name                = string
        data_source         = string
        event_configuration = optional(string)
        type_ref            = optional(string)
        destinations = optional(list(object({
          target = string
          configuration = object({
            topic  = optional(string)
            retain = optional(string)
            qos    = optional(string)
          })
        })), [])
      }))
    })), [])
    management_groups = optional(list(object({
      name                           = string
      data_source                    = optional(string)
      management_group_configuration = optional(string)
      type_ref                       = optional(string)
      default_topic                  = optional(string)
      default_timeout_in_seconds     = optional(number, 100)
      actions = list(object({
        name                 = string
        action_type          = string
        target_uri           = string
        topic                = optional(string)
        timeout_in_seconds   = optional(number)
        action_configuration = optional(string)
        type_ref             = optional(string)
      }))
    })), [])
  }))
  description = "List of namespaced assets with enhanced configuration support"
  default     = []

  validation {
    condition = alltrue([
      for asset in var.namespaced_assets : alltrue([
        for group in coalesce(asset.management_groups, []) : alltrue([
          for action in group.actions : contains(["Call", "Read", "Write"], action.action_type)
        ])
      ])
    ])
    error_message = "All management action types must be one of: Call, Read, or Write."
  }
}

variable "should_create_azure_functions" {
  type        = bool
  description = "Whether to create the Azure Functions resources including App Service Plan"
  default     = false
}

/*
 * MQTT Configuration
 */

variable "enterprise_broker_port" {
  type        = number
  description = "The port number for the enterprise MQTT broker listener"
  default     = 28883
  validation {
    condition     = var.enterprise_broker_port > 0 && var.enterprise_broker_port <= 65535
    error_message = "Enterprise broker port must be between 1 and 65535."
  }
}

variable "enterprise_broker_tls_cert_secret_name" {
  type        = string
  description = "The name of the Kubernetes secret containing the broker tls certificate"
  default     = "broker-tls-cert"
}

variable "enterprise_client_ca_configmap_name" {
  type        = string
  description = "The name of the Kubernetes configmap containing the client CA certificate"
  default     = "client-ca"
}

variable "site_client_secret_name" {
  type        = string
  description = "The name of the Kubernetes secret containing the client certificate and key"
  default     = "client-secret"
}

variable "site_tls_ca_configmap_name" {
  type        = string
  description = "The name of the Kubernetes configmap containing the TLS CA certificate"
  default     = "tls-ca-configmap"
}

/*
 * Certificate Configuration
 */

variable "external_certificates" {
  type = object({
    server_root_ca_cert         = string
    server_root_ca_key          = string
    server_intermediate_ca_cert = string
    server_intermediate_ca_key  = string
    server_leaf_cert            = string
    server_leaf_key             = string
    client_root_ca_cert         = string
    client_root_ca_key          = string
    client_intermediate_ca_cert = string
    client_intermediate_ca_key  = string
    client_leaf_cert            = string
    client_leaf_key             = string
  })
  description = "External certificates to use instead of generating them with Terraform. When null, certificates will be generated using the terraform-certificate-generation module."
  default     = null
  sensitive   = true
}
