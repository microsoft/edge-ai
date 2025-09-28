/*
 * Azure Machine Learning Extension Configuration
 */

variable "extension_name" {
  type        = string
  description = "Name of the Azure ML extension. Otherwise, 'azureml-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

variable "should_enable_training" {
  type        = bool
  description = "Whether to enable training workloads on the Arc-enabled cluster"
  default     = true
}

variable "should_enable_inference" {
  type        = bool
  description = "Whether to enable inference workloads on the Arc-enabled cluster"
  default     = true
}

variable "should_enable_inference_router_ha" {
  type        = bool
  description = "Whether to enable high availability for inference router"
  default     = true
}

variable "inference_router_service_type" {
  type        = string
  description = "Service type for inference router: LoadBalancer, NodePort, or ClusterIP"
  default     = "ClusterIP"
  validation {
    condition     = contains(["LoadBalancer", "NodePort", "ClusterIP"], var.inference_router_service_type)
    error_message = "Inference router service type must be LoadBalancer, NodePort, or ClusterIP."
  }
}

variable "should_install_dcgm_exporter" {
  type        = bool
  description = "Whether to install DCGM exporter for GPU metrics collection"
  default     = false
}

variable "should_install_nvidia_device_plugin" {
  type        = bool
  description = "Whether to install NVIDIA Device Plugin for GPU hardware support"
  default     = false
}

variable "should_install_prom_op" {
  type        = bool
  description = "Whether to install Prometheus operator for monitoring"
  default     = false
}

variable "should_install_volcano" {
  type        = bool
  description = "Whether to install Volcano scheduler for job scheduling"
  default     = false
}

/*
 * SSL/TLS Configuration
 */

variable "ssl_cname" {
  type        = string
  description = "CNAME used for HTTPS endpoint; required when providing cert/key; otherwise empty"
  default     = null
}

variable "ssl_cert_pem" {
  type        = string
  description = "PEM-encoded TLS certificate chain (server first then intermediates) or empty when not using HTTPS"
  default     = null
  sensitive   = true
}

variable "ssl_key_pem" {
  type        = string
  description = "PEM-encoded unencrypted private key matching ssl_cert_pem or empty when not using HTTPS"
  default     = null
  sensitive   = true
}

variable "workspace_identity_principal_id" {
  type        = string
  description = "Principal ID of workspace managed identity for role assignments. Otherwise, roles not assigned."
  default     = null
}


variable "arc_compute_target_name" {
  type        = string
  description = "Name of Arc compute target in ML workspace. Otherwise, 'arc-compute-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

variable "arc_cluster_purpose" {
  type        = string
  description = "Purpose of Arc cluster: DevTest, DenseProd, or FastProd"
  default     = "DevTest"
}

/*
 * Arc Extension Toleration Configuration - Optional
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
  description = "Description for the Arc integration compute target. Otherwise, 'Azure ML Arc compute target for {resource_prefix}-{environment}-{instance}'."
  default     = null
}

variable "cluster_integration_disable_local_auth" {
  type        = bool
  description = "Whether to disable local authentication for the Arc integration compute target."
  default     = true
}

/*
 * Workload Identity Federation - Optional
 */

variable "ml_workload_subjects" {
  type        = list(string)
  description = "Custom Kubernetes service account subjects for AzureML workload federation. Example: ['system:serviceaccount:azureml:azureml-workload', 'system:serviceaccount:osmo:osmo-workload']"
  default     = null
}
