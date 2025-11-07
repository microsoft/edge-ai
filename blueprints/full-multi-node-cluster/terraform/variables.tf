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

variable "should_use_arc_machines" {
  type        = bool
  description = "Whether to orchestrate the cluster using existing Arc-enabled servers instead of deploying Azure virtual machines"
  default     = false
}

variable "arc_machine_count" {
  type        = number
  description = "Number of Arc-enabled machines to target for the cluster when should_use_arc_machines is true"
  default     = 1
}

variable "arc_machine_name_prefix" {
  type        = string
  description = "Prefix for the Arc-enabled machine names; otherwise resource_prefix when should_use_arc_machines is true"
  default     = null
}

variable "arc_machine_resource_group_name" {
  type        = string
  description = "Resource group name that contains the Arc-enabled servers when should_use_arc_machines is true"
  default     = null
}

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
 * Edge Cluster Parameters
 */

variable "host_machine_count" {
  type        = number
  description = "Number of edge host virtual machines to create for the multi-node cluster"
  default     = 3
}

variable "cluster_server_host_machine_username" {
  type        = string
  description = <<-EOT
  Username for the Arc or VM host machines that receive kube-config during setup
  Otherwise, resource_prefix when the user exists on the machine
  EOT
  default     = null
}

variable "cluster_server_ip" {
  type        = string
  description = "IP address for the cluster server used by node machines when should_use_arc_machines is true"
  default     = null
  validation {
    condition     = var.should_use_arc_machines ? can(regex("^.+$", coalesce(var.cluster_server_ip, ""))) : true
    error_message = "cluster_server_ip is required when should_use_arc_machines is true"
  }
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
  default     = false
}

variable "should_enable_opc_ua_simulator" {
  type        = bool
  description = "Whether to deploy the OPC UA simulator to the cluster"
  default     = false
}

variable "should_enable_otel_collector" {
  type        = bool
  description = "Whether to deploy the OpenTelemetry Collector and Azure Monitor ConfigMap"
  default     = true
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
  default     = false
}

variable "aks_should_enable_private_cluster_public_fqdn" {
  type        = bool
  description = "Whether to create a private cluster public FQDN for AKS"
  default     = false
}

variable "aks_private_dns_zone_id" {
  type        = string
  description = "ID of the private DNS zone to use for AKS private cluster. Use 'system', 'none', or a resource ID"
  default     = null
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix for the AKS cluster. When null a value is generated"
  default     = null
}

variable "node_count" {
  type        = number
  description = "Number of nodes for the agent pool in the AKS cluster"
  default     = 1
}

variable "node_vm_size" {
  type        = string
  description = "VM size for the agent pool in the AKS cluster"
  default     = "Standard_D8ds_v5"
}

variable "enable_auto_scaling" {
  type        = bool
  description = "Whether to enable auto-scaling for the default node pool"
  default     = false
}

variable "min_count" {
  type        = number
  description = "Minimum node count for the default node pool"
  default     = null
}

variable "max_count" {
  type        = number
  description = "Maximum node count for the default node pool"
  default     = null
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

variable "should_enable_private_endpoints" {
  type        = bool
  description = "Whether to enable private endpoints across Key Vault, storage, and observability resources so Prometheus ingestion remains on private link"
  default     = false
}

variable "should_enable_workload_identity" {
  type        = bool
  description = "Whether to enable Azure AD workload identity for the cluster"
  default     = true
}

variable "subnet_address_prefixes_aks" {
  type        = list(string)
  description = "Address prefixes for the AKS subnet"
  default     = ["10.0.4.0/24"]
}

variable "subnet_address_prefixes_aks_pod" {
  type        = list(string)
  description = "Address prefixes for the AKS pod subnet"
  default     = ["10.0.5.0/24"]
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
    common_name         = optional(string, "Full Multi Node VPN Gateway Root Certificate")
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
  description = "Site-to-site VPN connection definitions. Provide on-premises address spaces that do not overlap with Azure VNets"
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
  description = "Fallback IPsec parameters applied when site definitions omit ipsec_policy"
  default     = null
}

variable "vpn_site_shared_keys" {
  type        = map(string)
  description = "Pre-shared keys for site connections keyed by shared_key_reference. Manage values in secure secret stores"
  default     = {}
  sensitive   = true
}
