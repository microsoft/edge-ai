/*
 * Optional Variables
 */

variable "should_create_event_hubs" {
  description = "Whether to create the Event Hubs resources."
  type        = bool
  default     = true
}

variable "should_create_event_grid" {
  description = "Whether to create the Event Grid resources."
  type        = bool
  default     = true
}
