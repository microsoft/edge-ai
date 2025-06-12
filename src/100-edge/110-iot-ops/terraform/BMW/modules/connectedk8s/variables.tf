variable "cluster_name" {
  type = string
  description = "Name of the created ARC K8s cluster"
}

variable "azure_resource_group" {
  type = object({
    id        = string
    location  = string
  })
  description = "Azure resource group"
  
}

variable "private_key_pem" {
  type = string
  description = "Private key for onboarding"
}
