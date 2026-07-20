/**
 * # Azure IoT Operations Cloud Requirements
 *
 * Sets up required cloud resources for Azure IoT Operations installation
 * including: Schema Registry, Azure Key Vault, and Roles and Permissions for
 * access to resources.
 */

data "azurerm_client_config" "current" {}

data "external" "deployment_client_ip" {
  count = var.should_use_network_security_perimeter ? 1 : 0

  program = ["bash", "-c", <<-EOT
    set -euo pipefail
    for endpoint in \
      "https://api64.ipify.org" \
      "https://ifconfig.me/ip" \
      "https://icanhazip.com"; do
      if public_ip=$(curl --fail --silent --retry 2 --max-time 10 "$${endpoint}"); then
        printf '{"ip":"%s"}\n' "$${public_ip}"
        exit 0
      fi
    done
    printf 'Unable to detect the deployment client public IP address\n' >&2
    exit 1
  EOT
  ]
}

locals {
  key_vault_admin_principal_id         = try(coalesce(var.key_vault_admin_principal_id, var.should_use_current_user_key_vault_admin ? data.azurerm_client_config.current.object_id : null), null)
  should_add_key_vault_role_assignment = anytrue([var.key_vault_admin_principal_id != null, var.should_use_current_user_key_vault_admin])
  deployment_client_ip                 = var.should_use_network_security_perimeter ? trimspace(data.external.deployment_client_ip[0].result.ip) : null
  deployment_client_ip_address_prefix  = var.should_use_network_security_perimeter ? "${local.deployment_client_ip}${strcontains(local.deployment_client_ip, ":") ? "/128" : "/32"}" : null
  network_security_perimeter_allowed_ip_address_prefixes = var.should_use_network_security_perimeter ? distinct(concat(
    var.network_security_perimeter_allowed_ip_address_prefixes,
    [local.deployment_client_ip_address_prefix]
  )) : []
}

check "deployment_client_ip" {
  assert {
    condition     = !var.should_use_network_security_perimeter || can(cidrhost(local.deployment_client_ip_address_prefix, 0))
    error_message = "The deployment client's public IP address could not be detected as a valid IPv4 or IPv6 address"
  }
}

module "network_security_perimeter" {
  count = var.should_use_network_security_perimeter ? 1 : 0

  source = "./modules/network-security-perimeter"

  allowed_ip_address_prefixes = local.network_security_perimeter_allowed_ip_address_prefixes
  environment                 = var.environment
  instance                    = var.instance
  location                    = var.location
  resource_group_id           = var.aio_resource_group.id
  resource_prefix             = var.resource_prefix
  subscription_id             = data.azurerm_client_config.current.subscription_id
}

module "key_vault" {
  count = var.should_create_key_vault ? 1 : 0

  source = "./modules/key-vault"

  location                                       = var.location
  resource_group                                 = var.aio_resource_group
  resource_prefix                                = var.resource_prefix
  environment                                    = var.environment
  instance                                       = var.instance
  key_vault_name                                 = var.key_vault_name
  key_vault_admin_principal_id                   = local.key_vault_admin_principal_id
  should_create_private_endpoint                 = var.should_create_key_vault_private_endpoint
  private_endpoint_subnet_id                     = var.key_vault_private_endpoint_subnet_id
  virtual_network_id                             = var.key_vault_virtual_network_id
  should_enable_public_network_access            = var.should_enable_public_network_access
  should_enable_purge_protection                 = var.should_enable_purge_protection
  should_add_key_vault_role_assignment           = local.should_add_key_vault_role_assignment
  log_analytics_workspace_id                     = var.log_analytics_workspace_id
  should_enable_diagnostic_settings              = var.should_enable_diagnostic_settings
  should_use_network_security_perimeter          = var.should_use_network_security_perimeter
  network_security_perimeter_id                  = try(module.network_security_perimeter[0].id, null)
  network_security_perimeter_profile_id          = try(module.network_security_perimeter[0].profile_id, null)
  network_security_perimeter_propagation_delay   = var.network_security_perimeter_propagation_delay
  network_security_perimeter_propagation_trigger = try(module.network_security_perimeter[0].propagation_trigger, null)
}

module "identity" {
  count = var.should_create_identities ? 1 : 0

  source = "./modules/identity"

  location                           = var.location
  resource_group                     = var.aio_resource_group
  resource_prefix                    = var.resource_prefix
  environment                        = var.environment
  instance                           = var.instance
  onboard_identity_type              = var.onboard_identity_type
  should_create_aks_identity         = var.should_create_aks_identity
  should_create_secret_sync_identity = var.should_create_secret_sync_identity
  should_create_aio_identity         = var.should_create_aio_identity
  should_create_ml_workload_identity = var.should_create_ml_workload_identity
}
