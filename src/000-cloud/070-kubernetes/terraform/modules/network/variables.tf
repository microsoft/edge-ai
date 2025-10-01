variable "default_outbound_access_enabled" {
  type        = bool
  description = "Whether to enable default outbound internet access for AKS subnets"
}

variable "nat_gateway_id" {
  type        = string
  description = "NAT gateway resource id for associating AKS subnets"
}

variable "subnet_address_prefixes_aks" {
  type        = list(string)
  description = "Address prefixes for the AKS subnet."
}

variable "subnet_address_prefixes_aks_pod" {
  type        = list(string)
  description = "Address prefixes for the AKS pod subnet."
}

variable "node_pools" {
  type = map(object({
    subnet_address_prefixes     = list(string)
    pod_subnet_address_prefixes = list(string)
  }))
  description = "Configuration for additional node pool subnets. Map key is used as the node pool name."
  default     = {}
}

variable "should_enable_private_endpoint" {
  type        = bool
  description = "Whether to enable private endpoint for AKS cluster. When true, subnet delegations are created."
}
