/**
 * # Notification CI
 *
 * Minimal deployment configuration for CI testing of the notification component.
 */

module "notification" {
  source = "../../"

  environment     = "dev"
  resource_prefix = "ci"
  instance        = "001"

  resource_group = {
    name     = "rg-ci-dev-001"
    id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ci-dev-001"
    location = "eastus2"
  }

  eventhub_namespace = {
    id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ci-dev-001/providers/Microsoft.EventHub/namespaces/evhns-ci-dev-001"
    name = "evhns-ci-dev-001"
  }

  key_vault = {
    id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ci-dev-001/providers/Microsoft.KeyVault/vaults/kv-ci-dev-001"
    name      = "kv-ci-dev-001"
    vault_uri = "https://kv-ci-dev-001.vault.azure.net/"
  }

  should_assign_roles = false
}
