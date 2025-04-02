output "eventstream_id" {
  description = "The ID of the created event stream"
  value       = fabric_eventstream.this.id
}

output "eventstream_name" {
  description = "The name of the created event stream"
  value       = fabric_eventstream.this.display_name
}
