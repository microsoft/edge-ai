# Create a Microsoft Fabric EventStream for real-time data ingestion
# Documentation: https://learn.microsoft.com/fabric/real-time-analytics/event-streams/create-manage-an-event-stream

resource "fabric_eventstream" "this" {
  display_name = var.eventstream_display_name
  description  = var.eventstream_description
  workspace_id = var.workspace_id

  # Standard format for EventStream
  format = "Default"

  # Define the EventStream configuration with Azure Event Grid as source and Lakehouse as destination
  definition = {
    "eventstream.json" = {
      # Ensure the template file exists at this path - create the directory if needed
      source = "${path.module}/templates/eventstream.json"
      tokens = {
        "WorkspaceID"      = var.workspace_id
        "LakehouseID"      = var.lakehouse_id
        "EventHubEndpoint" = var.eventhub_endpoint
      }
    }
  }
}
