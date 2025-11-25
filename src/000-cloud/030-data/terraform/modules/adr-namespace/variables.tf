variable "messaging_endpoints" {
  type = map(object({
    endpointType = string
    address      = string
    resourceId   = optional(string)
  }))
  description = "Dictionary of messaging endpoints for the namespace."
}

variable "enable_system_assigned_identity" {
  type        = bool
  description = "Whether to enable system-assigned managed identity for the namespace."
}
