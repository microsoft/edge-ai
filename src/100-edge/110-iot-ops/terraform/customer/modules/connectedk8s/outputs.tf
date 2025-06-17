output "cluster_name" {
  value = azapi_resource.arc.name
}

output "cluster_id" {
  value = azapi_resource.arc.id
}

output "cluster" {
  value = azapi_resource.arc
}

output "oidc_issuer_url" {
  value = azapi_resource.arc.output.properties.oidcIssuerProfile.issuerUrl
}