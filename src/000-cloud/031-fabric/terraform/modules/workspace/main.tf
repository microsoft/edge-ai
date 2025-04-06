# Use the Fabric Terraform provider to create a workspace
# Documentation: https://aka.ms/fabric/terraform

resource "fabric_workspace" "this" {
  display_name = var.workspace_display_name
  description  = var.workspace_description
  capacity_id  = var.capacity_id
}
