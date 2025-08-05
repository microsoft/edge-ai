output "workspace" {
  description = "The Fabric workspace."
  value = {
    id           = fabric_workspace.this.id
    display_name = fabric_workspace.this.display_name
  }
}
