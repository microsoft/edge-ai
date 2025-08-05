/**
 * # Eventhouse Module
 *
 * Creates a Microsoft Fabric Eventhouse and KQL database for real-time analytics.
 * The Eventhouse provides a high-performance analytics engine optimized for
 * time-series and telemetry data from IoT devices and streaming sources.
 */

// Create a Microsoft Fabric Eventhouse for real-time analytics
// Documentation: https://learn.microsoft.com/fabric/real-time-intelligence/eventhouse

resource "fabric_eventhouse" "this" {
  display_name = var.eventhouse_display_name
  description  = var.eventhouse_description
  workspace_id = var.workspace_id
}

// Optional additional KQL databases based on configuration
resource "fabric_kql_database" "additional" {
  for_each = var.additional_kql_databases

  display_name = each.value.display_name
  description  = each.value.description
  workspace_id = var.workspace_id

  configuration = {
    database_type = "ReadWrite"
    eventhouse_id = fabric_eventhouse.this.id
  }
}
