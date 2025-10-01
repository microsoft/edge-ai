/*
 * Azure Machine Learning Compute Cluster Module Variables
 */

variable "description" {
  type        = string
  description = "Description of the compute cluster."
}

variable "environment" {
  type        = string
  description = "The environment for the deployment."
}

variable "instance" {
  type        = string
  description = "Instance identifier for the deployment."
}

variable "location" {
  type        = string
  description = "Azure region where the cluster will be created."
}

variable "machine_learning_workspace_id" {
  type        = string
  description = "Resource ID of the Machine Learning workspace."
}

variable "max_node_count" {
  type        = number
  description = "Maximum number of nodes in compute cluster for auto-scaling."
}

variable "min_node_count" {
  type        = number
  description = "Minimum number of nodes in compute cluster for auto-scaling."
}

variable "name" {
  type        = string
  description = "Name of the compute cluster."
}

variable "node_public_ip_enabled" {
  type        = bool
  description = "Whether the compute cluster nodes will have public IPs. Should be false for private endpoint scenarios."
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resource names."
}

variable "scale_down_nodes_after_idle_duration" {
  type        = string
  description = "Time to wait before scaling down idle nodes (format: PT{minutes}M)."
}

variable "ssh_public_access_enabled" {
  type        = bool
  description = "Whether to enable public SSH port access to compute cluster nodes. Should be false for private endpoint scenarios."
}

variable "vm_priority" {
  type        = string
  description = "VM priority for compute cluster nodes (Dedicated or LowPriority)."
}

variable "vm_size" {
  type        = string
  description = "VM size for compute cluster nodes."
}
