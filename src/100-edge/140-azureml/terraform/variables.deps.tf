/*
 * Required Variables
 */

variable "connected_cluster" {
  type = object({
    id   = string
    name = string
  })
  description = "Connected cluster object containing id and name for Arc-enabled Kubernetes cluster"
}

variable "resource_group" {
  type = object({
    id   = string
    name = string
  })
  description = "Resource group object containing name and id where Arc-connected cluster and relay resources reside"
}

variable "machine_learning_workspace" {
  type = object({
    id       = string
    name     = string
    location = string
  })
  description = "Azure Machine Learning workspace object containing id, name, and location for compute target attachment"
}

variable "ml_workload_identity" {
  type = object({
    id           = string
    principal_id = string
  })
  description = "AzureML workload managed identity object containing id and principal_id."
  default     = null
}
