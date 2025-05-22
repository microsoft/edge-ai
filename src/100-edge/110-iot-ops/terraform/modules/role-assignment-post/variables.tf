variable "k8s_bridge_principal_id" {
  type        = string
  description = "The principal ID of the K8 Bridge that will be assigned the role. This will be automatically retrieved if not provided."
}

variable "custom_location_id" {
  type        = string
  description = "The Resource ID of the custom location"
}
