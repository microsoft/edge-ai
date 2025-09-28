/*
 * Extension Configuration
 */

variable "extension_name" {
  type        = string
  description = "Name of the Azure ML extension"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources"
}

variable "environment" {
  type        = string
  description = "Environment for the deployment"
}

variable "instance" {
  type        = string
  description = "Instance identifier for the deployment"
}

variable "cluster_id" {
  type        = string
  description = "Resource ID of Arc-enabled connected cluster"
}

variable "cluster_name" {
  type        = string
  description = "Name of the Arc-enabled connected cluster"
}

variable "enable_training" {
  type        = bool
  description = "Whether to enable training workloads on the cluster"
}

variable "enable_inference" {
  type        = bool
  description = "Whether to enable inference workloads on the cluster"
}

variable "inference_router_ha" {
  type        = bool
  description = "Whether to enable high availability for inference router"
}

variable "inference_router_service_type" {
  type        = string
  description = "Service type for inference router: LoadBalancer, NodePort, or ClusterIP"
}

variable "should_install_dcgm_exporter" {
  type        = bool
  description = "Whether to install DCGM exporter for GPU metrics collection"
}

variable "should_install_nvidia_device_plugin" {
  type        = bool
  description = "Whether to install NVIDIA Device Plugin for GPU hardware support"
}

variable "should_install_prom_op" {
  type        = bool
  description = "Whether to install Prometheus operator for monitoring"
}

variable "should_install_volcano" {
  type        = bool
  description = "Whether to install Volcano scheduler for job scheduling"
}

/*
 * SSL Configuration - Optional
 */

variable "ssl_cname" {
  type        = string
  description = "CNAME used for HTTPS endpoint"
}

variable "ssl_cert_pem" {
  type        = string
  description = "PEM-encoded TLS certificate chain"
  sensitive   = true
}

variable "ssl_key_pem" {
  type        = string
  description = "PEM-encoded private key"
  sensitive   = true
}

variable "workspace_identity_principal_id" {
  type        = string
  description = "Principal ID of the workspace managed identity for role assignments"
}

variable "cluster_resource_group_id" {
  type        = string
  description = "Resource group ID containing the Arc connected cluster. Otherwise derived from cluster_id."
}

variable "machine_learning_workspace_id" {
  type        = string
  description = "Resource ID of the Azure ML workspace for compute target attachment"
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "compute_target_name" {
  type        = string
  description = "Name of the Arc compute target. Otherwise, 'arc-compute-{resource_prefix}-{environment}-{instance}'"
}

variable "cluster_purpose" {
  type        = string
  description = "Purpose of cluster: DevTest, DenseProd, or FastProd"
}

variable "ml_workload_identity" {
  type = object({
    id           = string
    principal_id = string
  })
  description = "AzureML workload managed identity object containing id and principal_id."
}

variable "ml_workload_subjects" {
  type        = list(string)
  description = "Custom Kubernetes service account subjects for AzureML workload federation."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group containing the workload identity."
}

/*
 * Toleration Configuration - Optional
 */

variable "system_tolerations" {
  type = list(object({
    key      = optional(string)
    operator = string
    value    = optional(string)
    effect   = optional(string)
  }))
  description = "List of tolerations for AzureML extension system components to schedule on tainted nodes."
}

variable "workload_tolerations" {
  type = list(object({
    key      = optional(string)
    operator = string
    value    = optional(string)
    effect   = optional(string)
  }))
  description = "List of tolerations for AzureML workloads (training and inference jobs) to schedule on tainted nodes."
}

/*
 * Kubernetes Compute Configuration - Optional
 */

variable "default_instance_type" {
  type        = string
  description = "Default instance type for the Kubernetes compute."
}

variable "extension_instance_release_train" {
  type        = string
  description = "Extension instance release train for Azure ML extension."
}

variable "instance_types" {
  type = map(object({
    nodeSelector = optional(map(string))
    resources = optional(object({
      requests = optional(map(string))
      limits   = optional(map(string))
    }))
  }))
  description = "Instance types configuration for Kubernetes compute. Key is the instance type name, value contains nodeSelector and resource specifications."
}

variable "kubernetes_namespace" {
  type        = string
  description = "Kubernetes namespace for ML workloads. Otherwise, 'azureml'."
}

variable "workspace_identity_id" {
  type        = string
  description = "Resource ID of user-assigned managed identity for the compute target. If null, SystemAssigned identity will be used."
}

variable "vc_name" {
  type        = string
  description = "Virtual Cluster (VC) name for advanced Kubernetes compute configuration."
}

variable "description" {
  type        = string
  description = "Description for the Arc integration compute target."
}

variable "disable_local_auth" {
  type        = bool
  description = "Whether to disable local authentication for the Arc integration compute target."
}
