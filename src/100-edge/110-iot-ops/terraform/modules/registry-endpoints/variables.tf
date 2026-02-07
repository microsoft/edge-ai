/*
 * Required Dependencies
 */

variable "aio_instance_id" {
  type        = string
  description = "Azure IoT Operations instance ID (parent for registry endpoints)"
}

variable "custom_location_id" {
  type        = string
  description = "Custom location ID for the Azure IoT Operations deployment"
}

variable "extension_principal_id" {
  type        = string
  description = "Principal ID of the AIO Arc extension's system-assigned identity for ACR role assignments"
}

/*
 * Registry Endpoints Configuration
 */

variable "registry_endpoints" {
  type = list(object({
    name                           = string
    host                           = string
    acr_resource_id                = optional(string)
    should_assign_acr_pull_for_aio = optional(bool, false)
    authentication = object({
      method = string
      system_assigned_managed_identity_settings = optional(object({
        audience = optional(string, "https://management.azure.com/")
      }))
      user_assigned_managed_identity_settings = optional(object({
        client_id = string
        tenant_id = string
        scope     = optional(string)
      }))
      artifact_pull_secret_settings = optional(object({
        secret_ref = string
      }))
    })
  }))
  description = "List of custom registry endpoints to configure."
}
