/**
 * # Variables for K8 Bridge Role Assignment Module
 *
 * This file defines variables for the K8 Bridge role assignment module.
 */

variable "custom_location_id" {
  type        = string
  description = "The Resource ID of the custom location."
}

variable "k8s_bridge_principal_id" {
  type        = string
  default     = null
  description = "The principal ID of the K8 Bridge that will be assigned the role. If null, will be automatically retrieved using the service principal data source."
}
