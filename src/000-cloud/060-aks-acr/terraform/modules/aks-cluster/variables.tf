
variable "node_count" {
  type        = number
  description = "Number of nodes for the agent pool in the AKS cluster."
}

variable "node_vm_size" {
  type        = string
  description = "VM size for the agent pool in the AKS cluster. Default is Standard_D8ds_v5."
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix for the AKS cluster. This is used to create a unique DNS name for the cluster. If not provided, a default value will be generated."
}
