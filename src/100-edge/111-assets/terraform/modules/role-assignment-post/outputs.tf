/**
 * # Outputs for K8 Bridge Role Assignment Module
 *
 * This file defines outputs from the K8 Bridge role assignment module.
 */

output "role_assignment_id" {
  description = "The ID of the role assignment created for the K8 Bridge."
  value       = azurerm_role_assignment.k8_bridge_role_assignment.id
}

output "k8s_bridge_principal_id" {
  description = "The principal ID of the K8 Bridge service principal used."
  value       = local.k8s_bridge_principal_id
}
