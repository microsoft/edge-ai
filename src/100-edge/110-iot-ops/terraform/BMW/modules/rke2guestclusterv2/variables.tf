##########################################
### Variables
##########################################

variable "rancher_api_url" {
  type = string
}

variable "rancher_access_key" {
  type        = string
  description = "Access key of the token"
}

variable "rancher_secret_key" {
  type        = string
  description = "Secret key of the token"
}

variable "harvester_cluster_id" {
  type        = string
  description = "Harvester cluster id"
}

variable "harvester_cloud_credential_name" {
  type        = string
  description = "Name of the Harvester Cloud Credential created as part of the prerequisites"
}

variable "system_default_registry" {
  type        = string
  description = "hostname:port of the system default registry"
}

variable "container_registry_mirrors" {
  type        = map(any)
  description = "map of container registry mirrors"
}

variable "cluster_name" {
  type        = string
  description = "Cluster display name"
}

variable "harvester_namespace" {
  type        = string
  description = "Harvester namespace where the guest cluster will be deployed"
}

variable "rke2_version" {
  type        = string
  description = "RKE2 version you want to deploy"
}

variable "container_network" {
  type        = string
  description = "Specify the container network CNI name"
  default     = "calico"
}

variable "cilium_options" {
  type = object({
    enable_egressGateway = bool
    enable_hubble        = bool
  })
}

variable "agent_environment_vars" {
  type        = map(any)
  description = "map of agent environment variables"
}

variable "enable_network_policy" {
  type        = bool
  description = "Enable network policies in the guest cluster"
  default     = false
}

variable "local_auth_endpoint" {
  type        = bool
  description = "Expose the local auth endpoint of the guest cluster"
  default     = false
}

variable "enable_kube_vip" {
  type        = bool
  description = "Enable kube-vip in the guest cluster"
  default     = false
}

variable "kubelet_args_max_pods" {
  type        = number
  description = "The amount of pods per node"
  default     = 100
}

variable "node_network_cidr" {
  type        = number
  description = "The network CIDR per node network"
  default     = 24
}

variable "machine_global_config" {
  type = object({
    kube_controller_manager_arg = optional(list(string), [])
    kube_apiserver_arg          = optional(list(string), [])
    disable_kube_proxy          = optional(bool, false)
    etcd_expose_metrics         = optional(bool, false)
  })
  description = "map of machine global config"
  default     = {}
}

variable "nginx_enable_ssl_passthrough" {
  type        = bool
  description = "Toggle SSL Passthrough in Nginx Ingress Controller"
  default     = false
}

variable "cluster_admin_group_name" {
  type        = string
  description = "Group name which gets the cluster-admin role"
}

variable "rancher_machine_pools" {
  type = list(object({
    name                 = string
    node_count           = number
    cpu_count            = number
    memory_size          = number
    disk_size            = number
    network_name         = string
    image_name           = string
    ssh_user             = string
    availability_zone    = string
    labels               = map(string)
    control_plane_role   = bool
    etcd_role            = bool
    worker_role          = bool
    user_data            = string
  }))
  description = "map with all the Rancher machine pools and options"
}

variable "additional_manifest" {
  type = string
  description = "additional Kubernetes manifests"
  default = ""
}