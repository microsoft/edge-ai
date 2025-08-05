/*
 * Optional Variables
 */

variable "asset_name" {
  type        = string
  description = "The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud."
  default     = "oven"
}

variable "should_create_eventgrid_dataflows" {
  type        = bool
  description = "Whether to create event grid dataflows."
  default     = true
}

variable "should_create_eventhub_dataflows" {
  type        = bool
  description = "Whether to create event hub dataflows."
  default     = true
}

variable "should_create_fabric_rti_dataflows" {
  type        = bool
  description = "Whether to create fabric RTI dataflows."
  default     = false
}
