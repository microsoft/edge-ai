/*
 * Required Variables
 */

variable "closure_message_template" {
  type        = string
  description = "HTML message body for session-closure Teams notifications. Supports Logic App expression syntax for dynamic fields"
}

variable "event_schema" {
  type        = any
  description = "JSON schema object for parsing Event Hub events in the Logic App Parse_Event action"
}

variable "eventhub_name" {
  type        = string
  description = "Name of the Event Hub to subscribe to for events"
}

variable "eventhub_namespace" {
  type = object({
    id   = string
    name = string
  })
  description = "Event Hub namespace for Logic App trigger connectivity and role assignment"
}

variable "extra_entity_fields" {
  type        = map(any)
  description = "Additional fields merged into the default insert entity body. Ignored when insert_entity_body is provided. Otherwise, '{}'"
  default     = {}
}

variable "insert_entity_body" {
  type        = any
  description = "Table Storage entity body for inserting a new session record. Otherwise, auto-generated from partition_key_field with session tracking fields"
  default     = null
}

variable "notification_message_template" {
  type        = string
  description = "HTML template for new-event Teams notifications. Supports Terraform template variable: close_session_url. Supports Logic App expression syntax for dynamic event fields"
}

variable "partition_key_field" {
  type        = string
  description = "Event schema field name used as the Table Storage partition key for session state deduplication lookups"
}

variable "resource_group" {
  type = object({
    name     = string
    id       = string
    location = string
  })
  description = "Resource group object containing name and id where resources will be deployed"
}

variable "storage_account" {
  type = object({
    id   = string
    name = string
  })
  description = "Storage account for event session state tracking via Table Storage"
}

variable "teams_group_id" {
  type        = string
  description = "Microsoft 365 Group ID (Team ID) for posting to a Teams channel. Required when teams_post_location is 'Channel'"
  default     = null
}

variable "teams_recipient_id" {
  type        = string
  description = "Teams chat or channel thread ID for posting event notifications"
}

variable "update_entity_body" {
  type        = any
  description = "Table Storage entity body for updating an existing session record. Otherwise, auto-generated with LastEventAt timestamp and EventCount increment"
  default     = null
}
