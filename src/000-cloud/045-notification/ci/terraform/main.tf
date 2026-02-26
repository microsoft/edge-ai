/**
 * # Notification CI
 *
 * Minimal deployment configuration for CI testing of the notification component.
 */

module "notification" {
  source = "../../terraform"

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

  eventhub_name = "evh-aio-sample"

  storage_account = {
    id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ci-dev-001/providers/Microsoft.Storage/storageAccounts/stcidev001"
    name = "stcidev001"
  }

  teams_recipient_id = "19:mock-thread-id@thread.v2"

  should_assign_roles = false
}
