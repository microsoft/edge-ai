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

/*
 * Core Parameters - Optional
 */

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
  default     = "001"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to create or use. Otherwise, 'rg-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

variable "use_existing_resource_group" {
  type        = bool
  description = "Whether to use an existing resource group with the provided or computed name instead of creating a new one"
  default     = false
}

/*
 * Azure Arc Parameters
 */

variable "custom_locations_oid" {
  type        = string
  description = <<-EOT
  The object id of the Custom Locations Entra ID application for your tenant
  If none is provided, the script attempts to retrieve this value which requires 'Application.Read.All' or 'Directory.Read.All' permissions

  ```sh
  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
  ```
  EOT
  default     = null
}

variable "should_add_current_user_cluster_admin" {
  type        = bool
  description = "Whether to give the current signed-in user cluster-admin permissions on the new cluster"
  default     = true
}

variable "should_get_custom_locations_oid" {
  type        = bool
  description = <<-EOT
  Whether to get the Custom Locations object ID using Terraform's azuread provider
  Otherwise, provide 'custom_locations_oid' or rely on `az connectedk8s enable-features` during cluster setup
  EOT
  default     = true
}

/*
 * Azure IoT Operations Parameters
 */

variable "aio_features" {
  description = "AIO instance features with mode ('Stable', 'Preview', 'Disabled') and settings ('Enabled', 'Disabled')"
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
  description = "List of namespaced devices to create; otherwise, an empty list"
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

/*
 * Azure Functions Parameters
 */

variable "should_create_azure_functions" {
  type        = bool
  description = "Whether to create the Azure Functions resources including the App Service plan"
  default     = false
}

/*
 * Azure Kubernetes Service Parameters
 */

variable "aks_should_enable_private_cluster" {
  type        = bool
  description = "Whether to enable private cluster mode for AKS"
  default     = true
}

variable "aks_should_enable_private_cluster_public_fqdn" {
  type        = bool
  description = "Whether to create a private cluster public FQDN for AKS"
  default     = false
}

variable "node_count" {
  type        = number
  description = "Number of nodes for the agent pool in the AKS cluster"
  default     = 1
}

variable "node_pools" {
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
  description = "Additional node pools for the AKS cluster; map key is used as the node pool name"
  default     = {}
}

variable "node_vm_size" {
  type        = string
  description = "VM size for the agent pool in the AKS cluster"
  default     = "Standard_D8ds_v5"
}

variable "should_create_aks" {
  type        = bool
  description = "Whether to deploy Azure Kubernetes Service"
  default     = false
}

variable "should_enable_oidc_issuer" {
  type        = bool
  description = "Whether to enable the OIDC issuer URL for the cluster"
  default     = true
}

variable "should_enable_workload_identity" {
  type        = bool
  description = "Whether to enable Azure AD workload identity for the cluster"
  default     = true
}

/*
 * Azure Machine Learning Parameters
 */

variable "azureml_registry_should_enable_public_network_access" {
  type        = bool
  description = "Whether to enable public network access to the Azure Machine Learning registry when deployed"
  default     = true
}

variable "azureml_should_create_compute_cluster" {
  type        = bool
  description = "Whether to create a compute cluster for Azure Machine Learning training workloads"
  default     = true
}

variable "azureml_should_deploy_registry" {
  type        = bool
  description = "Whether to deploy Azure Machine Learning registry resources alongside the workspace"
  default     = false
}

variable "azureml_should_enable_private_endpoint" {
  type        = bool
  description = "Whether to enable a private endpoint for the Azure Machine Learning workspace"
  default     = false
}

variable "azureml_should_enable_public_network_access" {
  type        = bool
  description = "Whether to enable public network access to the Azure Machine Learning workspace"
  default     = true
}

variable "azureml_should_create_ml_workload_identity" {
  type        = bool
  description = "Whether to create a user-assigned managed identity for AzureML workload federation."
  default     = false
}

variable "azureml_ml_workload_subjects" {
  type        = list(string)
  description = "Custom Kubernetes service account subjects for AzureML workload federation. Example: ['system:serviceaccount:azureml:azureml-workload', 'system:serviceaccount:osmo:osmo-workload']"
  default     = null
}

variable "should_deploy_azureml" {
  type        = bool
  description = "Whether to deploy the Azure Machine Learning workspace and optional compute cluster"
  default     = false
}

variable "should_deploy_edge_azureml" {
  type        = bool
  description = "Whether to deploy the Azure Machine Learning edge extension when Azure ML is enabled"
  default     = false
}

/*
 * Azure Private Endpoint and DNS Parameters
 */

variable "resolver_subnet_address_prefix" {
  type        = string
  description = "Address prefix for the private resolver subnet; must be /28 or larger and not overlap with other subnets"
  default     = "10.0.9.0/28"
}

variable "should_enable_private_endpoints" {
  type        = bool
  description = "Whether to enable private endpoints across Key Vault, storage, and observability resources to route monitoring ingestion through private link"
  default     = false
}

variable "should_enable_private_resolver" {
  type        = bool
  description = "Whether to enable Azure Private Resolver for VPN client DNS resolution of private endpoints"
  default     = false
}

/*
 * Azure Container Registry Parameters
 */

variable "acr_sku" {
  type        = string
  description = "SKU name for the Azure Container Registry"
  default     = "Premium"
}

variable "acr_allow_trusted_services" {
  type        = bool
  description = "Whether trusted Azure services can bypass ACR network rules"
  default     = true
}

variable "acr_allowed_public_ip_ranges" {
  type        = list(string)
  description = "CIDR ranges permitted to reach the ACR public endpoint"
  default     = []
}

variable "acr_data_endpoint_enabled" {
  type        = bool
  description = "Whether to enable the dedicated ACR data endpoint"
  default     = true
}

variable "acr_public_network_access_enabled" {
  type        = bool
  description = "Whether to enable the ACR public endpoint alongside private connectivity"
  default     = false
}

/*
 * Identity and Key Vault Parameters
 */

variable "should_create_aks_identity" {
  type        = bool
  description = "Whether to create a user-assigned identity for the AKS cluster when using custom private DNS zones"
  default     = false
}

variable "should_enable_key_vault_public_network_access" {
  type        = bool
  description = "Whether to enable public network access for the Key Vault"
  default     = true
}

/*
 * Networking and Outbound Access Parameters
 */

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
  description = "Availability zones for NAT gateway resources when zone redundancy is required (example: ['1','2'])"
  default     = []
}

variable "should_enable_managed_outbound_access" {
  type        = bool
  description = "Whether to enable managed outbound egress via NAT gateway instead of platform default internet access"
  default     = true
}

/*
 * Storage Parameters
 */

variable "should_enable_storage_public_network_access" {
  type        = bool
  description = "Whether to enable public network access for the storage account"
  default     = true
}

variable "storage_account_is_hns_enabled" {
  type        = bool
  description = "Whether to enable hierarchical namespace on the storage account when Azure Machine Learning is not deployed; automatically forced to false when should_deploy_azureml is true"
  default     = true
}

/*
 * PostgreSQL Configuration
 */

variable "should_deploy_postgresql" {
  type        = bool
  description = "Whether to deploy PostgreSQL Flexible Server component"
  default     = false
}

variable "postgresql_admin_password" {
  type        = string
  description = "Administrator password for PostgreSQL server. (Otherwise, generated when postgresql_should_generate_admin_password is true)."
  sensitive   = true
  default     = null
}

variable "postgresql_should_generate_admin_password" {
  type        = bool
  description = "Whether to auto-generate PostgreSQL admin password."
  default     = true
}

variable "postgresql_should_store_credentials_in_key_vault" {
  type        = bool
  description = "Whether to store PostgreSQL admin credentials in Key Vault."
  default     = true
}

variable "postgresql_admin_username" {
  type        = string
  description = "Administrator username for PostgreSQL server"
  default     = "pgadmin"
}

variable "postgresql_databases" {
  type = map(object({
    collation = string
    charset   = string
  }))
  description = "Map of databases to create with collation and charset"
  default     = null
}

variable "postgresql_delegated_subnet_id" {
  type        = string
  description = "Subnet ID with delegation to Microsoft.DBforPostgreSQL/flexibleServers"
  default     = null
}

variable "postgresql_should_enable_geo_redundant_backup" {
  type        = bool
  description = "Whether to enable geo-redundant backups for PostgreSQL"
  default     = false
}

variable "postgresql_should_enable_extensions" {
  type        = bool
  description = "Whether to enable PostgreSQL extensions via azure.extensions"
  default     = true
}

variable "postgresql_should_enable_timescaledb" {
  type        = bool
  description = "Whether to enable TimescaleDB extension for PostgreSQL"
  default     = true
}

variable "postgresql_sku_name" {
  type        = string
  description = "SKU name for PostgreSQL server"
  default     = "GP_Standard_D2s_v3"
}

variable "postgresql_storage_mb" {
  type        = number
  description = "Storage size in megabytes for PostgreSQL"
  default     = 32768
}

variable "postgresql_version" {
  type        = string
  description = "PostgreSQL server version"
  default     = "16"
}

/*
 * Azure Managed Redis Configuration
 */

variable "should_deploy_redis" {
  type        = bool
  description = "Whether to deploy Azure Managed Redis component"
  default     = false
}

variable "redis_sku_name" {
  type        = string
  description = "SKU name for Azure Managed Redis cache"
  default     = "Balanced_B10"
}

variable "redis_should_enable_high_availability" {
  type        = bool
  description = "Whether to enable high availability for Redis cache"
  default     = true
}

variable "redis_clustering_policy" {
  type        = string
  description = "Clustering policy for Redis cache (OSSCluster or EnterpriseCluster)"
  default     = "OSSCluster"

  validation {
    condition     = contains(["OSSCluster", "EnterpriseCluster"], var.redis_clustering_policy)
    error_message = "Clustering policy must be either OSSCluster or EnterpriseCluster."
  }
}

/*
 * VPN Gateway Parameters
 */

variable "certificate_subject" {
  type = object({
    common_name         = optional(string, "Full Single Node VPN Gateway Root Certificate")
    organization        = optional(string, "Edge AI Accelerator")
    organizational_unit = optional(string, "IT")
    country             = optional(string, "US")
    province            = optional(string, "WA")
    locality            = optional(string, "Redmond")
  })
  description = "Certificate subject information for auto-generated certificates"
  default     = {}
}

variable "certificate_validity_days" {
  type        = number
  description = "Validity period in days for auto-generated certificates"
  default     = 365
}

variable "existing_certificate_name" {
  type        = string
  description = "Name of the existing certificate in Key Vault when vpn_gateway_should_generate_ca is false"
  default     = null
}

variable "should_enable_vpn_gateway" {
  type        = bool
  description = "Whether to create a VPN gateway for secure access to private endpoints"
  default     = false
}

variable "vpn_gateway_config" {
  type = object({
    sku                 = optional(string, "VpnGw1")
    generation          = optional(string, "Generation1")
    client_address_pool = optional(list(string), ["192.168.200.0/24"])
    protocols           = optional(list(string), ["OpenVPN", "IkeV2"])
  })
  description = "VPN gateway configuration including SKU, generation, client address pool, and supported protocols"
  default     = {}
}

variable "vpn_gateway_should_generate_ca" {
  type        = bool
  description = "Whether to generate a new CA certificate; when false, uses an existing certificate from Key Vault"
  default     = true
}

variable "vpn_gateway_should_use_azure_ad_auth" {
  type        = bool
  description = "Whether to use Azure AD authentication for the VPN gateway; otherwise, certificate authentication is used"
  default     = true
}

variable "vpn_gateway_subnet_address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the GatewaySubnet; must be /27 or larger"
  default     = ["10.0.2.0/27"]
}

variable "vpn_site_connections" {
  type = list(object({
    name                       = string
    address_spaces             = list(string)
    shared_key_reference       = string
    connection_mode            = optional(string, "Default")
    dpd_timeout_seconds        = optional(number)
    gateway_fqdn               = optional(string)
    gateway_ip_address         = optional(string)
    ike_protocol               = optional(string, "IKEv2")
    use_policy_based_selectors = optional(bool, false)
    bgp_settings = optional(object({
      asn          = number
      peer_address = string
      peer_weight  = optional(number)
    }))
    ipsec_policy = optional(object({
      dh_group            = string
      ike_encryption      = string
      ike_integrity       = string
      ipsec_encryption    = string
      ipsec_integrity     = string
      pfs_group           = string
      sa_datasize_kb      = optional(number)
      sa_lifetime_seconds = optional(number)
    }))
  }))
  description = "Site-to-site VPN site definitions. Use non-overlapping on-premises address spaces and reference shared keys via shared_key_reference"
  default     = []
}

variable "vpn_site_default_ipsec_policy" {
  type = object({
    dh_group            = string
    ike_encryption      = string
    ike_integrity       = string
    ipsec_encryption    = string
    ipsec_integrity     = string
    pfs_group           = string
    sa_datasize_kb      = optional(number)
    sa_lifetime_seconds = optional(number)
  })
  description = "Fallback IPsec policy applied when site definitions omit ipsec_policy overrides"
  default     = null
}

variable "vpn_site_shared_keys" {
  type        = map(string)
  description = "Pre-shared keys for site definitions keyed by shared_key_reference. Source values from secure secret storage"
  default     = {}
  sensitive   = true
}

/*
 * Akri Connector Configuration - Optional
 */

variable "should_enable_akri_rest_connector" {
  type        = bool
  description = "Whether to deploy the Akri REST HTTP Connector template to the IoT Operations instance."
  default     = false
}

variable "should_enable_akri_media_connector" {
  type        = bool
  description = "Whether to deploy the Akri Media Connector template to the IoT Operations instance."
  default     = false
}

variable "should_enable_akri_onvif_connector" {
  type        = bool
  description = "Whether to deploy the Akri ONVIF Connector template to the IoT Operations instance."
  default     = false
}

variable "should_enable_akri_sse_connector" {
  type        = bool
  description = "Whether to deploy the Akri SSE Connector template to the IoT Operations instance."
  default     = false
}

variable "custom_akri_connectors" {
  type = list(object({
    name = string
    type = string // "rest", "media", "onvif", "sse", "custom"

    // Custom Connector Fields (required when type = "custom")
    custom_endpoint_type    = optional(string) // e.g., "Contoso.Modbus", "Acme.CustomProtocol"
    custom_image_name       = optional(string) // e.g., "my_acr.azurecr.io/custom-connector"
    custom_endpoint_version = optional(string, "1.0")

    // Runtime Configuration (defaults applied based on connector type)
    registry          = optional(string) // Defaults: mcr.microsoft.com for built-in types
    image_tag         = optional(string) // Defaults: 0.5.1 for built-in types, latest for custom
    replicas          = optional(number, 1)
    image_pull_policy = optional(string) // Default: IfNotPresent

    // Diagnostics
    log_level = optional(string) // Default: info (lowercase: trace, debug, info, warning, error, critical)

    // MQTT Override (uses shared config if not provided)
    mqtt_config = optional(object({
      host                   = string
      audience               = string
      ca_configmap           = string
      keep_alive_seconds     = optional(number, 60)
      max_inflight_messages  = optional(number, 100)
      session_expiry_seconds = optional(number, 600)
    }))

    // Optional Advanced Fields
    aio_min_version = optional(string)
    aio_max_version = optional(string)
    allocation = optional(object({
      policy      = string // "Bucketized"
      bucket_size = number // 1-100
    }))
    additional_configuration = optional(map(string))
    secrets = optional(list(object({
      secret_alias = string
      secret_key   = string
      secret_ref   = string
    })))
    trust_settings = optional(object({
      trust_list_secret_ref = string
    }))
  }))

  default     = []
  description = <<-EOT
    List of custom Akri connector templates with user-defined endpoint types and container images.
    Supports built-in types (rest, media, onvif, sse) or custom types with custom_endpoint_type and custom_image_name.
    Built-in connectors default to mcr.microsoft.com/azureiotoperations/akri-connectors/connector_type:0.5.1.
  EOT

  validation {
    condition = alltrue([
      for conn in var.custom_akri_connectors :
      contains(["rest", "media", "onvif", "sse", "custom"], conn.type)
    ])
    error_message = "Connector type must be one of: rest, media, onvif, sse, custom."
  }

  validation {
    condition = alltrue([
      for conn in var.custom_akri_connectors :
      conn.type != "custom" || (conn.custom_endpoint_type != null && conn.custom_image_name != null)
    ])
    error_message = "Custom connector types must provide custom_endpoint_type and custom_image_name."
  }

  validation {
    condition = alltrue([
      for conn in var.custom_akri_connectors :
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", conn.name))
    ])
    error_message = "Connector name must contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }

  validation {
    condition = alltrue([
      for conn in var.custom_akri_connectors :
      contains(["trace", "debug", "info", "warning", "error", "critical"], lower(coalesce(conn.log_level, "info")))
    ])
    error_message = "Log level must be one of: trace, debug, info, warning, error, critical (case insensitive)."
  }

  validation {
    condition = alltrue([
      for conn in var.custom_akri_connectors :
      coalesce(conn.replicas, 1) >= 1 && coalesce(conn.replicas, 1) <= 10
    ])
    error_message = "Connector replicas must be between 1 and 10."
  }
}

# ------------------------------------------------------------------------------
# AI Foundry Variables
# ------------------------------------------------------------------------------

variable "should_deploy_ai_foundry" {
  type        = bool
  default     = false
  description = "Whether to deploy Azure AI Foundry resources"
}

variable "ai_foundry_sku" {
  type        = string
  default     = "S0"
  description = "SKU name for the AI Foundry account"
}

variable "ai_foundry_should_enable_public_network_access" {
  type        = bool
  default     = true
  description = "Whether to enable public network access to AI Foundry"
}

variable "ai_foundry_should_enable_local_auth" {
  type        = bool
  default     = true
  description = "Whether to enable local (API key) authentication for AI Foundry"
}

variable "ai_foundry_should_enable_private_endpoint" {
  type        = bool
  default     = false
  description = "Whether to enable private endpoint for AI Foundry"
}

variable "ai_foundry_private_dns_zone_ids" {
  type        = list(string)
  default     = []
  description = "List of private DNS zone IDs for the AI Foundry private endpoint"
}

variable "ai_foundry_projects" {
  type = map(object({
    name         = string
    display_name = string
    description  = string
    sku          = optional(string, "S0")
  }))
  default     = {}
  description = "Map of AI Foundry projects to create. SKU defaults to 'S0' (currently the only supported value)"
}

variable "ai_foundry_model_deployments" {
  type = map(object({
    name = string
    model = object({
      format  = string
      name    = string
      version = string
    })
    scale = object({
      type     = string
      capacity = number
    })
    rai_policy_name        = optional(string)
    version_upgrade_option = optional(string, "OnceNewDefaultVersionAvailable")
  }))
  default     = {}
  description = "Map of model deployments for AI Foundry"
}

variable "ai_foundry_rai_policies" {
  type = map(object({
    name             = string
    base_policy_name = optional(string, "Microsoft.Default")
    mode             = optional(string, "Blocking")
    content_filters = optional(list(object({
      name               = string
      enabled            = optional(bool, true)
      blocking           = optional(bool, true)
      severity_threshold = optional(string, "Medium")
      source             = string
    })), [])
  }))
  default     = {}
  description = "Map of Responsible AI (RAI) content filtering policies. Must be created before referenced in model deployments."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources in this blueprint"
}
