output "lakehouse_id" {
  description = "The ID of the created lakehouse"
  value       = fabric_lakehouse.this.id
}

output "lakehouse_name" {
  description = "The name of the created lakehouse"
  value       = fabric_lakehouse.this.display_name
}
