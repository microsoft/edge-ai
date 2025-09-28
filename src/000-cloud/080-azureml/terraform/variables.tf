/*
 * Azure Machine Learning Workspace Configuration
 */

variable "should_assign_current_user_workspace_roles" {
  type        = bool
  description = "Whether to assign the current Azure AD user roles for accessing and using the Machine Learning workspace (Contributor on workspace and Storage Blob Data Contributor on storage account)."
  default     = true
}

variable "should_assign_workspace_managed_identity_roles" {
  type        = bool
  description = "Whether to assign the workspace system-assigned managed identity roles to access dependent Azure services (Storage, ACR, Key Vault, Application Insights)."
  default     = true
}

variable "should_enable_public_network_access" {
  type        = bool
  description = "Whether to enable public network access to the workspace."
  default     = false
}

variable "workspace_name" {
  type        = string
  description = "Name of the Azure Machine Learning workspace. Otherwise, 'mlw-{resource_prefix}-{environment}-{instance}'."
  default     = null
}

variable "workspace_friendly_name" {
  type        = string
  description = "Friendly display name for the workspace. (Default, {var.resource_prefix}-{var.environment}-{var.instance} ML Workspace)"
  default     = null
}

/*
 * Private Endpoint Configuration - Optional
 */

variable "should_enable_private_endpoint" {
  type        = bool
  description = "Whether to create a private endpoint for the Azure ML workspace"
  default     = false
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "The ID of the subnet where the private endpoint will be created"
  default     = null
}

variable "virtual_network_id" {
  type        = string
  description = "The ID of the virtual network to link to the private DNS zone"
  default     = null
}

/*
 * Network Configuration - Optional
 */

variable "network_security_group" {
  type = object({
    id = string
  })
  description = "Network security group from 050-networking component."
  default     = null
}

variable "virtual_network" {
  type = object({
    name = string
  })
  description = "Virtual network from 050-networking component."
  default     = null
}

variable "nat_gateway" {
  type = object({
    id   = string
    name = string
  })
  description = "NAT gateway object from the networking component for managed outbound access."
  default     = null
}

variable "should_create_compute_cluster_snet" {
  type        = bool
  description = "Whether to create the subnet for the Azure ML compute cluster."
  default     = true
}

variable "subnet_address_prefixes_azureml" {
  type        = list(string)
  description = "Address prefixes for the Azure ML compute cluster subnet."
  default     = ["10.0.4.0/24"]
}

/*
 * Outbound Access Controls - Optional
 */

variable "default_outbound_access_enabled" {
  type        = bool
  description = "Whether to enable default outbound internet access for Azure ML subnets"
  default     = false
}

/*
 * Compute Cluster Configuration
 */

variable "should_create_compute_cluster" {
  type        = bool
  description = "Whether to create a compute cluster for ML training workloads."
  default     = true
}

variable "compute_cluster_name" {
  type        = string
  description = "Name of the compute cluster for ML training workloads. Otherwise, 'cluster-{resource_prefix}-{environment}-{instance}'."
  default     = null
}

variable "compute_cluster_idle_duration" {
  type        = string
  description = "Time to wait before scaling down idle nodes. Format: PT{minutes}M (e.g., PT15M for 30 minutes)."
  default     = "PT30M"
}

variable "compute_cluster_max_nodes" {
  type        = number
  description = "Maximum number of nodes in compute cluster for auto-scaling. Default: 1 (cost-optimized for single-model training)."
  default     = 1

  validation {
    condition     = var.compute_cluster_max_nodes >= 1
    error_message = "Maximum node count must be at least 1."
  }
}

variable "compute_cluster_min_nodes" {
  type        = number
  description = "Minimum number of nodes in compute cluster for auto-scaling. Default: 0 (cost-optimized, scales to zero when idle)."
  default     = 0

  validation {
    condition     = var.compute_cluster_min_nodes >= 0 && var.compute_cluster_min_nodes <= var.compute_cluster_max_nodes
    error_message = "Minimum node count must be greater than or equal to 0 and less than or equal to compute_cluster_max_nodes."
  }
}

variable "compute_cluster_vm_priority" {
  type        = string
  description = "VM priority for compute cluster nodes: Dedicated (production, higher cost) or LowPriority (development, 60-80% cost savings but can be preempted)."
  default     = "Dedicated"

  validation {
    condition     = contains(["Dedicated", "LowPriority"], var.compute_cluster_vm_priority)
    error_message = "VM priority must be either 'Dedicated' or 'LowPriority'."
  }
}

variable "compute_cluster_vm_size" {
  type        = string
  description = "VM size for compute cluster nodes. Standard_DS3_v2 (4 vCPUs, 14 GiB RAM) recommended for balanced production ML workloads."
  default     = "Standard_DS3_v2"
}

variable "compute_cluster_node_public_ip_enabled" {
  type        = bool
  description = "Whether the compute cluster nodes will have public IPs. Set to false for private endpoint scenarios to enhance security."
  default     = false
}

variable "compute_cluster_ssh_public_access_enabled" {
  type        = bool
  description = "Whether to enable public SSH port access to compute cluster nodes. Set to false for private endpoint scenarios to prevent unauthorized access."
  default     = false
}

/*
 * Azure Machine Learning AKS Integration Configuration - Optional
 */

variable "should_integrate_aks_cluster" {
  type        = bool
  description = "Whether to integrate an existing AKS cluster as compute target for ML workloads."
  default     = false
}

variable "extension_name" {
  type        = string
  description = "Name of the Azure ML extension for AKS cluster. Otherwise, 'azureml-{resource_prefix}-{environment}-{instance}'."
  default     = null
}

variable "aks_compute_target_name" {
  type        = string
  description = "Name of the AKS compute target in ML workspace. Otherwise, 'ml{resource_prefix_clean}{environment_clean}{instance}' truncated to 16 characters."
  default     = null
}

variable "should_enable_aks_training" {
  type        = bool
  description = "Whether to enable training workloads on the AKS cluster."
  default     = true
}

variable "should_enable_aks_inference" {
  type        = bool
  description = "Whether to enable inference workloads on the AKS cluster."
  default     = true
}

variable "should_enable_inference_router_ha" {
  type        = bool
  description = "Whether to enable high availability for inference router."
  default     = true
}

variable "inference_router_service_type" {
  type        = string
  description = "Service type for inference router: LoadBalancer, NodePort, or ClusterIP."
  default     = "ClusterIP"
  validation {
    condition     = contains(["LoadBalancer", "NodePort", "ClusterIP"], var.inference_router_service_type)
    error_message = "Inference router service type must be LoadBalancer, NodePort, or ClusterIP."
  }
}

variable "should_install_dcgm_exporter" {
  type        = bool
  description = "Whether to install DCGM exporter for GPU metrics collection in Azure ML extension."
  default     = true
}

variable "should_install_nvidia_device_plugin" {
  type        = bool
  description = "Whether to install NVIDIA Device Plugin for GPU hardware support in Azure ML extension."
  default     = false
}

variable "should_install_prom_op" {
  type        = bool
  description = "Whether to install Prometheus operator for monitoring in Azure ML extension. Set to false if Azure Monitor is already enabled on AKS."
  default     = false
}

variable "should_install_volcano" {
  type        = bool
  description = "Whether to install Volcano scheduler for job scheduling in Azure ML extension."
  default     = true
}

variable "aks_cluster_purpose" {
  type        = string
  description = "Purpose of AKS cluster: DevTest, DenseProd, or FastProd."
  default     = "DevTest"
  validation {
    condition     = contains(["DevTest", "DenseProd", "FastProd"], var.aks_cluster_purpose)
    error_message = "AKS cluster purpose must be DevTest, DenseProd, or FastProd."
  }
}

variable "ssl_cname" {
  type        = string
  description = "CNAME used for HTTPS endpoint; required when providing cert/key; otherwise empty."
  default     = null
}

variable "ssl_cert_pem" {
  type        = string
  description = "PEM-encoded TLS certificate chain (server first then intermediates) or empty when not using HTTPS."
  default     = null
  sensitive   = true
}

variable "ssl_key_pem" {
  type        = string
  description = "PEM-encoded unencrypted private key matching ssl_cert_pem or empty when not using HTTPS."
  default     = null
  sensitive   = true
}

/*
 * AKS Extension Toleration Configuration - Optional
 */

variable "system_tolerations" {
  type = list(object({
    key      = optional(string)
    operator = optional(string, "Exists")
    value    = optional(string)
    effect   = optional(string)
  }))
  description = "Tolerations for AzureML extension system components to schedule on tainted nodes. Default: empty list (no tolerations)."
  default     = []
}

variable "workload_tolerations" {
  type = list(object({
    key      = optional(string)
    operator = optional(string, "Exists")
    value    = optional(string)
    effect   = optional(string)
  }))
  description = "Tolerations for AzureML workloads (training and inference) to schedule on tainted nodes. Default: empty list (no tolerations)."
  default     = []
}

/*
 * Kubernetes Compute Configuration - Optional
 */

variable "cluster_integration_default_instance_type" {
  type        = string
  description = "Default instance type for the Kubernetes compute.."
  default     = "defaultinstancetype"
}

variable "cluster_integration_extension_instance_release_train" {
  type        = string
  description = "Extension instance release train for Azure ML extension."
  default     = "Stable"
}

variable "cluster_integration_instance_types" {
  type = map(object({
    nodeSelector = optional(map(string))
    resources = optional(object({
      requests = optional(map(string))
      limits   = optional(map(string))
    }))
  }))
  description = "Instance types configuration for Kubernetes compute. Key is the instance type name, value contains nodeSelector and resource specifications."
  default     = null
}

variable "cluster_integration_kubernetes_namespace" {
  type        = string
  description = "Kubernetes namespace for ML workloads. Otherwise, 'azureml'."
  default     = "azureml"
}

variable "cluster_integration_workspace_identity_id" {
  type        = string
  description = "Resource ID of user-assigned managed identity for the compute target. If null, SystemAssigned identity will be used."
  default     = null
}

variable "cluster_integration_vc_name" {
  type        = string
  description = "Virtual Cluster (VC) name for advanced Kubernetes compute configuration."
  default     = null
}

variable "cluster_integration_description" {
  type        = string
  description = "Description for the AKS integration compute target. Otherwise, 'Azure ML AKS compute target for {resource_prefix}-{environment}-{instance}'."
  default     = null
}

variable "cluster_integration_disable_local_auth" {
  type        = bool
  description = "Whether to disable local authentication for the AKS integration compute target."
  default     = true
}

variable "ml_workload_subjects" {
  type        = list(string)
  description = "Custom Kubernetes service account subjects for AzureML workload federation. Example: ['system:serviceaccount:azureml:azureml-workload', 'system:serviceaccount:osmo:osmo-workload']"
  default     = null
}

/*
 * Registry Configuration - Optional
 */

variable "should_deploy_registry" {
  type        = bool
  description = "Whether to deploy AzureML Registry."
  default     = false
}

variable "registry_description" {
  type        = string
  description = "Description for the AzureML Registry. Otherwise, 'Azure Machine Learning Registry for {resource_prefix}-{environment}-{instance}'"
  default     = null
}

variable "registry_should_enable_public_network_access" {
  type        = bool
  description = "Whether to enable public network access to the registry."
  default     = false
}

variable "registry_storage_account" {
  type = object({
    id   = string
    name = string
  })
  description = "Storage account for registry (from cloud data component)"
  default     = null
}

variable "registry_acr" {
  type = object({
    id   = string
    name = string
  })
  description = "Azure Container Registry for registry (from cloud ACR component)"
  default     = null
}
