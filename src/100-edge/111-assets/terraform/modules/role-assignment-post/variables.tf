/**
 * # Variables for K8 Bridge Role Assignment Module
 *
 * This file defines variables for the K8 Bridge role assignment module.
 */

variable "custom_location_id" {
  type        = string
  description = "The resource ID of the Custom Location."
}

variable "k8s_bridge_principal_id" {
  type        = string
  default     = null
  description = <<-EOT
Optional. The principal ID of the K8 Bridge for Azure IoT Operations.
Required only if enable_asset_discovery=true and automatic retrieval fails.
If null and enable_asset_discovery=true, will be automatically retrieved using the service principal data source.

Can be retrieved manually using:

  az ad sp list --display-name \"K8 Bridge\" --query \"[0].appId\" -o tsv
EOT
}
