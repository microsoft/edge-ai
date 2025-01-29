/**
 * # Azure IoT Instance post-installation enablement 
 *
 * Enables secret-sync on the Azure IoT instance after the instance is created.
 *
 */

data "azurerm_subscription" "current" {}

resource "azapi_resource" "default_aio_keyvault_secret_provider_class" {
  type      = "Microsoft.SecretSyncController/azureKeyVaultSecretProviderClasses@2024-08-21-preview"
  name      = "spc-ops-aio" # Name can be anything, as the Digital Operations Experience (DOE) searches for the SPC by the custom location and resource group, this is not documented but found through default install values and testing
  location  = var.connected_cluster_location
  parent_id = var.resource_group.id

  body = {
    extendedLocation = {
      name = var.custom_location_id
      type = "CustomLocation"
    }
    properties = {
      clientId     = var.sse_user_managed_identity.client_id
      keyvaultName = var.key_vault.name
      tenantId     = data.azurerm_subscription.current.tenant_id
    }
  }

  count = var.enable_instance_secret_sync ? 1 : 0
}

data "azapi_resource" "cluster_oidc_issuer" {
  name      = var.connected_cluster_name
  parent_id = var.resource_group.id
  type      = "Microsoft.Kubernetes/connectedClusters@2024-12-01-preview"

  response_export_values = ["properties.oidcIssuerProfile.issuerUrl"]
}

resource "azurerm_federated_identity_credential" "federated_identity_cred_sse_aio" {
  name                = "aio-sse-ficred"
  resource_group_name = var.resource_group.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = data.azapi_resource.cluster_oidc_issuer.output.properties.oidcIssuerProfile.issuerUrl
  parent_id           = var.sse_user_managed_identity.id
  subject             = "system:serviceaccount:${var.aio_namespace}:aio-ssc-sa" # Service account name must be this value, this is currently not documented but hard-coded in CLI, eg here: https://github.com/Azure/azure-iot-ops-cli-extension/blob/dev/azext_edge/edge/providers/orchestration/resources/instances.py#L38
  count               = var.enable_instance_secret_sync ? 1 : 0
}

resource "azurerm_federated_identity_credential" "federated_identity_cred_aio_instance" {
  name                = "aio-instance-ficred"
  resource_group_name = var.resource_group.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = data.azapi_resource.cluster_oidc_issuer.output.properties.oidcIssuerProfile.issuerUrl
  parent_id           = var.aio_user_managed_identity_id
  subject             = "system:serviceaccount:${var.aio_namespace}:aio-dataflow" # Service account name must be this value, this is currently not documented but hard-coded in CLI, eg here: https://github.com/Azure/azure-iot-ops-cli-extension/blob/dev/azext_edge/edge/providers/orchestration/resources/instances.py#L37
}
