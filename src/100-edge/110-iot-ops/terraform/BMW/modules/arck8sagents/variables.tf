variable "azure_resource_group" {
  type        = object({
    name      = string
    location  = string
  })
  description = "Azure resource group"
}

variable "cluster_name" {
  type = string
  description = "Name of the created ARC K8s cluster"
}

variable "private_key_pem" {
  type = string
  description = "Private key for onboarding"
}

variable "http_proxy" {
  type        = string
  description = "HTTP proxy URL"
}

variable "custom_location_object_id" {
  type = string
  description = "Object ID of the custom location. Get by executing az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv"
}
