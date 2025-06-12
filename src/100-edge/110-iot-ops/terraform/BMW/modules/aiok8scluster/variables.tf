##########################################
### Variables
##########################################

variable "rancher_api_url" {
  type        = string
  description = "Url of the Rancher API"
}

variable "rancher_access_key" {
  type        = string
  description = "Access key of the token"
}

variable "rancher_secret_key" {
  type        = string
  description = "Secret key of the token"
}

variable "http_proxy" {
  type        = string
  description = "Configuration for providing an HTTP Proxy"
  sensitive = true
}

variable "cluster_name" {
  type = string
  description = "Name of the created ARC K8s cluster"
}

variable "azure_resource_group" {
  type = string
  description = "Azure resource group name"
  nullable = true
  default = null
}

variable "azure_location" {
  type = string
  description = "Azure location in which the ARC resource is created"
}

variable "azure_custom_location_name" {
  type       = string
  description = "The name of the custom location to be created."
  nullable = true
}

variable "k8s_bridge_identity_object_id" {
  type        = string
  description = "Object ID of the user assigned identity assigned to the K8s bridge. Get by executing az ad sp list --display-name \"K8 Bridge\" --query \"[0].id\" -o tsv"
  default = "b6e64865-051a-4e6a-b016-85de5e2b61b9" // This is the object ID of the K8s Bridge App for the BMW Group Azure Entra Tenant. This does normally not need to be changed.
}

variable "custom_location_object_id" {
  type = string
  description = "Object ID of the custom location app. Get by executing az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv"
  default = "1412e19c-38d3-458a-9215-ce40e28815b4" // This is the object ID of the custom location for the BMW Group Azure Entra Tenant. This does normally not need to be changed.
}

variable "rancher_config" {
  type        = object({
    harvester_cluster_id            = string
    harvester_cloud_credential_name = string
    system_default_registry         = optional(string, null)
    container_registry_mirrors      = optional(map(any), {
      "registry.rancher.com" = {
        endpoints = ["https://rancher.edge-registry.bmwgroup.net"]
      },
      "docker.io" = {
        endpoints = ["https://docker.edge-registry.bmwgroup.net"]
      }
    })
    harvester_namespace             = string
    k8s_version                     = string
    container_network               = optional(string, "cilium")
    cilium_options                  = optional(object({
      enable_egressGateway = bool
      enable_hubble        = bool
    }), {
      enable_egressGateway = true
      enable_hubble        = true
    })
    agent_environment_vars          = optional(map(string), null)
    enable_network_policy           = optional(bool, false)
    local_auth_endpoint             = optional(bool, true)
    enable_kube_vip                 = optional(bool, true)
    kubelet_args_max_pods           = optional(number, 100)
    node_network_cidr               = optional(number, 24)
    nginx_enable_ssl_passthrough    = optional(bool, false)
    cluster_admin_group_name        = optional(string, null)
    cluster_size                    = optional(string, "s")
    rancher_machine_pools           = optional(list(object({
      name                 = string
      node_count           = number
      cpu_count            = number
      memory_size          = number
      disk_size            = number
      network_name         = string
      image_name           = string
      ssh_user             = optional(string, "cloud")
      availability_zone    = string
      labels               = optional(map(string), {})
      control_plane_role   = bool
      etcd_role            = bool
      worker_role          = bool
      user_data            = optional(string, null)
    })), null)
  })
  description = "Map with rancher cluster config"
}

variable "disable_broker_cpu_limits" {
  type = bool
  description = "Disable CPU limits for the broker. The default is false."
  default = false
}

variable "aio_features" {
  type = object({
    connectors = bool
  })
  default = {
    connectors: false
  }
  description = "Additional AIO features to be enabled."
}

variable "schema_folder" {
  type = string
  description = "Path to the folder containing the schema folders."
}
