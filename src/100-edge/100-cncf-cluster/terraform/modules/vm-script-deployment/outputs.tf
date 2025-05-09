/*
 * VM Extension Outputs
 */

output "linux_extension_id" {
  description = "The ID of the Linux VM extension, if it was created."
  value       = try(azurerm_virtual_machine_extension.linux_script_deployment[0].id, null)
}

output "script_deployed" {
  description = "Whether a script was successfully deployed to the VM."
  value       = length(azurerm_virtual_machine_extension.linux_script_deployment) > 0
}
