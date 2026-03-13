/**
 * Video Capture Query Blueprint Outputs
 *
 * Exports storage connection information and Azure Functions URL for video query access.
 */

/*
 * Storage Account Outputs
 */

output "storage_account" {
  description = "Storage Account resource for video recordings."
  value       = module.cloud_data.storage_account
  sensitive   = true
}

output "storage_account_connection_string" {
  description = "Storage Account primary connection string for edge device configuration."
  value       = module.cloud_data.storage_account.primary_connection_string
  sensitive   = true
}

/*
 * Azure Functions Outputs
 */

output "function_app" {
  description = "Azure Function App resource for Video Query API."
  value       = module.cloud_messaging.function_app
}

output "function_app_url" {
  description = "Azure Function App default hostname URL."
  value       = try(module.cloud_messaging.function_app.default_hostname, null)
}

output "function_storage_account" {
  description = "Storage Account used by the Function App for internal state."
  value       = module.cloud_messaging.function_storage_account
  sensitive   = true
}

/*
 * Resource Group Outputs
 */

output "resource_group" {
  description = "Resource group for all video capture query resources."
  value       = module.cloud_resource_group.resource_group
}

/*
 * Configuration Outputs
 */

output "video_recording_config" {
  description = "Video recording configuration parameters for edge deployment."
  value = {
    recording_mode                = var.recording_mode
    segment_duration_seconds      = var.segment_duration_seconds
    video_retention_days          = var.video_retention_days
    storage_account_name          = module.cloud_data.storage_account.name
    storage_container_video       = "video-recordings"
    storage_container_temp        = "temp-videos"
    function_app_default_hostname = try(module.cloud_messaging.function_app.default_hostname, null)
  }
  sensitive = true
}
