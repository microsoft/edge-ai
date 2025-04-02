output "workspace_id" {
  description = "The ID of the created workspace"
  value       = fabric_workspace.this.id
}

output "workspace_name" {
  description = "The name of the created workspace"
  value       = fabric_workspace.this.display_name
}
