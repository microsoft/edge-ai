output "sp_client_id" {
  value = azuread_application.aio_edge.client_id
}

output "sp_client_secret" {
  value = azuread_application_password.aio_edge.value
}

