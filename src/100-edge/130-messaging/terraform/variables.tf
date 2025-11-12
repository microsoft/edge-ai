/*
 * Optional Variables
 */

variable "asset_name" {
  type        = string
  description = "The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud."
  default     = "namespace-oven"
}

variable "adr_namespace" {
  type = object({
    id   = string,
    name = string
  })
  description = "Azure Device Registry namespace to use with Azure IoT Operations. Otherwise, not configured."
  default     = null
}

variable "should_create_eventgrid_dataflows" {
  type        = bool
  description = "Whether to create EventGrid dataflows in the edge messaging component"
  default     = true
}

variable "should_create_eventhub_dataflows" {
  type        = bool
  description = "Whether to create EventHub dataflows in the edge messaging component"
  default     = true
}

variable "should_create_fabric_rti_dataflows" {
  type        = bool
  description = "Whether to create fabric RTI dataflows."
  default     = false
}
