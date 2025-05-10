/*
 * Arc Machine Extension Outputs
 */

output "linux_extension_id" {
  description = "The ID of the Linux Arc machine extension, if it was created."
  value       = try(azurerm_arc_machine_extension.linux_script_deployment[0].id, null)
}

output "script_deployed" {
  description = "Whether a script was successfully deployed to the Arc-connected machine."
  value       = length(azurerm_arc_machine_extension.linux_script_deployment) > 0
}
