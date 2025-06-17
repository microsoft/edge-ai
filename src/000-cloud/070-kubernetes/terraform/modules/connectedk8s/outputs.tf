output "connected_cluster_name" {
  value = azapi_resource.arc.name
}

output "connected_cluster_id" {
  value = azapi_resource.arc.id
}

output "oidc_issuer_url" {
  value = azapi_resource.arc.output.properties.oidcIssuerProfile.issuerUrl
}
