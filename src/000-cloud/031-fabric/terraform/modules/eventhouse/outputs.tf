/*
 * Eventhouse Outputs
 */

output "eventhouse_id" {
  description = "The ID of the created eventhouse."
  value       = fabric_eventhouse.this.id
}

output "eventhouse_name" {
  description = "The display name of the created eventhouse."
  value       = fabric_eventhouse.this.display_name
}

output "kql_database_ids" {
  description = "List of all KQL database IDs within the eventhouse."
  value       = [for db in fabric_kql_database.additional : db.id]
}

output "kql_databases" {
  description = "List of all KQL database objects with complete properties."
  value = [
    for db in fabric_kql_database.additional : {
      id           = db.id
      display_name = db.display_name
      description  = db.description
      workspace_id = db.workspace_id
      properties   = db.properties
    }
  ]
}

output "eventhouse" {
  description = "The complete eventhouse object with all properties."
  value = {
    id           = fabric_eventhouse.this.id
    display_name = fabric_eventhouse.this.display_name
    description  = fabric_eventhouse.this.description
    workspace_id = fabric_eventhouse.this.workspace_id
    properties = {
      database_ids              = fabric_eventhouse.this.properties.database_ids
      ingestion_service_uri     = fabric_eventhouse.this.properties.ingestion_service_uri
      minimum_consumption_units = fabric_eventhouse.this.properties.minimum_consumption_units
      query_service_uri         = fabric_eventhouse.this.properties.query_service_uri
    }
  }
}
