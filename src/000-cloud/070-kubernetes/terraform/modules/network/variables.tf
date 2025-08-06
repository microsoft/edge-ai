variable "subnet_address_prefixes_aks" {
  type        = list(string)
  description = "Address prefixes for the AKS subnet."
}

variable "subnet_address_prefixes_aks_pod" {
  type        = list(string)
  description = "Address prefixes for the AKS pod subnet."
}
