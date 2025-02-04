output "arc_onboarding_user_managed_identity_id" {
  description = "The User Assigned Managed Identity ID with 'Kubernetes Cluster - Azure Arc Onboarding' permissions."
  value       = try(module.onboard_identity[0].arc_onboarding_user_managed_identity_id, "")
}

output "arc_onboarding_user_managed_identity_name" {
  description = "The User Assigned Managed Identity name with 'Kubernetes Cluster - Azure Arc Onboarding' permissions."
  value       = try(module.onboard_identity[0].arc_onboarding_user_managed_identity_name, "")
}

output "arc_onboarding_sp_client_id" {
  description = "The Service Principal Client ID with 'Kubernetes Cluster - Azure Arc Onboarding' permissions."
  value       = try(module.onboard_identity[0].sp_client_id, "")
}

output "arc_onboarding_sp_client_secret" {
  description = <<-EOF
    The Service Principal Secret used for automation. `jq -r '.arc_onboard_sp_client_secret.value' <<< "$(terraform output -json)"`
EOF
  value       = try(module.onboard_identity[0].sp_client_secret, "")
  sensitive   = true
}

output "resource_group" {
  value = try(azurerm_resource_group.new[0], data.azurerm_resource_group.existing[0])
}

output "arc_onboarding_user_assigned_identity" {
  value = try(module.onboard_identity[0].arc_onboarding_user_assigned_identity, null)
}
