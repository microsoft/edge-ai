/*
 * Arc SSH Script Deployment Outputs
 */

output "ssh_endpoint_id" {
  description = "The ID of the Hybrid Connectivity default endpoint, if it was created."
  value       = try(azapi_resource.ssh_endpoint[0].id, null)
}

output "script_deployed" {
  description = "Whether a script was delivered to the Arc-connected machine over SSH."
  value       = terraform_data.ssh_script_deployment.id != null
}
