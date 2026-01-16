/**
 * # Azure IoT Enablement Module
 *
 * Deploys resources necessary to enable Azure IoT Operations (AIO) and creates an AIO instance.
 *
 */

data "azapi_resource" "cluster_oidc_issuer" {
  name      = var.connected_cluster_name
  parent_id = var.resource_group.id
  type      = "Microsoft.Kubernetes/connectedClusters@2024-12-01-preview"

  response_export_values = ["properties.oidcIssuerProfile.issuerUrl"]
}

resource "azurerm_arc_kubernetes_cluster_extension" "secret_store" {
  name           = "azure-secret-store"
  cluster_id     = var.arc_connected_cluster_id
  extension_type = "microsoft.azure.secretstore"
  identity {
    type = "SystemAssigned"
  }
  version       = var.secret_sync_controller.version
  release_train = var.secret_sync_controller.train
  configuration_settings = {
    "rotationPollIntervalInSeconds"             = "120"
    "validatingAdmissionPolicies.applyPolicies" = "false"
  }
}

resource "azurerm_federated_identity_credential" "federated_identity_cred_sse_aio" {
  count               = var.enable_instance_secret_sync ? 1 : 0
  name                = "aio-sse-ficred"
  resource_group_name = var.resource_group.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = data.azapi_resource.cluster_oidc_issuer.output.properties.oidcIssuerProfile.issuerUrl
  parent_id           = var.secret_sync_identity.id
  subject             = "system:serviceaccount:${var.aio_namespace}:aio-ssc-sa"
}

resource "azurerm_federated_identity_credential" "federated_identity_cred_aio_instance" {
  name                = "aio-instance-ficred"
  resource_group_name = var.resource_group.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = data.azapi_resource.cluster_oidc_issuer.output.properties.oidcIssuerProfile.issuerUrl
  parent_id           = var.aio_user_managed_identity_id
  subject             = "system:serviceaccount:${var.aio_namespace}:aio-dataflow"
}
