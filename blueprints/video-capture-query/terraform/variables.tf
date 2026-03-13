/*
 * Core Parameters - Required
 */

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"

  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z](?:-?[a-zA-Z0-9])*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes. Must start with an alphabetic character."
  }
}

/*
 * Core Parameters - Optional
 */

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
  default     = "001"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources in this blueprint"
  default     = {}
}

/*
 * Video Recording Parameters - Optional
 */

variable "recording_mode" {
  type        = string
  description = "Video recording mode: continuous, hybrid, or ring_buffer_only"
  default     = "continuous"

  validation {
    condition     = contains(["continuous", "hybrid", "ring_buffer_only"], var.recording_mode)
    error_message = "Recording mode must be continuous, hybrid, or ring_buffer_only."
  }
}

variable "segment_duration_seconds" {
  type        = number
  description = "Duration of each video segment in seconds"
  default     = 300

  validation {
    condition     = var.segment_duration_seconds > 0 && var.segment_duration_seconds <= 3600
    error_message = "Segment duration must be between 1 and 3600 seconds."
  }
}

variable "video_retention_days" {
  type        = number
  description = "Number of days to retain video files before deletion"
  default     = 365

  validation {
    condition     = var.video_retention_days > 0 && var.video_retention_days <= 3650
    error_message = "Video retention days must be between 1 and 3650."
  }
}
