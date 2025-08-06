output "site_mqtt_endpoint" {
  description = "The site MQTT endpoint resource."
  value       = azapi_resource.site_mqtt_endpoint
}

output "enterprise_mqtt_endpoint_cert_auth" {
  description = "The enterprise MQTT endpoint with certificate authentication."
  value       = azapi_resource.enterprise_mqtt_endpoint_cert_auth
}

output "site_enterprise_route_cert_auth" {
  description = "The enterprise site route with certificate authentication dataflow."
  value       = azapi_resource.site_enterprise_route_cert_auth
}

output "enterprise_mqtt_broker_authentication" {
  description = "The enterprise MQTT broker authentication resource."
  value       = azapi_resource.enterprise_mqtt_broker_authentication
}

output "enterprise_mqtt_broker_listener" {
  description = "The enterprise MQTT broker listener resource."
  value       = azapi_resource.enterprise_mqtt_broker_listener
}
