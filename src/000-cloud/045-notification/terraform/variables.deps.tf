/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name     = string
    id       = string
    location = string
  })
  description = "Resource group object containing name and id where resources will be deployed"
}

variable "eventhub_namespace" {
  type = object({
    id   = string
    name = string
  })
  description = "Event Hub namespace for Logic App trigger connectivity and role assignment"
}

variable "eventhub_name" {
  type        = string
  description = "Name of the Event Hub to subscribe to for leak detection events"
}
