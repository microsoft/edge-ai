/*
 * Optional Variables
 */

variable "should_create_aks" {
  type        = bool
  description = "Should create Azure Kubernetes Service. Default is false."
  default     = false
}

variable "should_create_arc_cluster_instance" {
  type        = bool
  description = "Should create an Azure Arc Cluster Instance. Default is false."
  default     = false
}

variable "node_count" {
  type        = number
  description = "Number of nodes for the agent pool in the AKS cluster."
  default     = 1
}

variable "node_vm_size" {
  type        = string
  description = "VM size for the agent pool in the AKS cluster. Default is Standard_D8ds_v5."
  default     = "Standard_D8ds_v5"
}

variable "dns_prefix" {
  type        = string
  default     = null
  description = "DNS prefix for the AKS cluster. This is used to create a unique DNS name for the cluster. If not provided, a default value will be generated."
}
