output "id" {
  description = "The ID of the run command execution."
  value       = azapi_resource_action.command_invoke.output.id
}

output "exit_code" {
  description = "The exit code of the command execution."
  value       = try(azapi_resource_action.command_invoke.output.properties.exitCode, null)
}

output "logs" {
  description = "The logs from the command execution."
  value       = try(azapi_resource_action.command_invoke.output.properties.logs, "")
}

output "success" {
  description = "Whether the command execution was successful (exit code 0)."
  value       = try(azapi_resource_action.command_invoke.output.properties.exitCode == 0, false)
}

output "provisioning_state" {
  description = "The provisioning state of the command execution."
  value       = try(azapi_resource_action.command_invoke.output.properties.provisioningState, null)
}
