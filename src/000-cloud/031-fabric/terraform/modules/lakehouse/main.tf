# Create a Microsoft Fabric Lakehouse in the specified workspace
# Documentation: https://aka.ms/fabric/lakehouse

resource "fabric_lakehouse" "this" {
  display_name = var.lakehouse_display_name
  description  = var.lakehouse_description
  workspace_id = var.workspace_id
}
