/*
 * Microsoft Foundry Account Outputs
 */

output "ai_foundry" {
  description = "The Microsoft Foundry account resource."
  value = {
    id           = azapi_resource.ai_foundry.id
    name         = azapi_resource.ai_foundry.name
    endpoint     = "https://${local.ai_foundry_name}.cognitiveservices.azure.com"
    principal_id = azapi_resource.ai_foundry.identity[0].principal_id
  }
}

output "ai_foundry_id" {
  description = "The resource ID of the Microsoft Foundry account."
  value       = azapi_resource.ai_foundry.id
}

output "ai_foundry_name" {
  description = "The name of the Microsoft Foundry account."
  value       = azapi_resource.ai_foundry.name
}

output "ai_foundry_endpoint" {
  description = "The endpoint URL of the Microsoft Foundry account."
  value       = "https://${local.ai_foundry_name}.cognitiveservices.azure.com"
}

output "ai_foundry_principal_id" {
  description = "The principal ID of the Microsoft Foundry account's system-assigned managed identity."
  value       = azapi_resource.ai_foundry.identity[0].principal_id
}

/*
 * Project Outputs
 */

output "projects" {
  description = "Map of Microsoft Foundry project resources."
  value = {
    for k, v in azapi_resource.project : k => {
      id           = v.id
      name         = v.name
      principal_id = v.identity[0].principal_id
    }
  }
}

/*
 * Deployment Outputs
 */

output "deployments" {
  description = "Map of model deployment resources."
  value = {
    for k, v in azapi_resource.deployment : k => {
      id   = v.id
      name = v.name
    }
  }
}

/*
 * RAI Policy Outputs
 */

output "rai_policies" {
  description = "Map of RAI policy resources."
  value = {
    for k, v in azapi_resource.rai_policy : k => {
      id   = v.id
      name = v.name
    }
  }
}

/*
 * Private Endpoint Outputs
 */

output "private_endpoint" {
  description = "The private endpoint resource (if created)."
  value       = try(azurerm_private_endpoint.ai_foundry[0], null)
}
