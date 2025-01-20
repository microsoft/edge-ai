/**
 * # Azure IoT Operations Customer Managed trust
 *
 * Deploys resources necessary to enable Azure IoT Operations (AIO) with Customer Managed trust.
 *
 */

data "azurerm_subscription" "current" {}

resource "azurerm_key_vault_secret" "aio_ca_key" {
  name         = "aio-ca-key"
  value        = var.aio_ca.ca_key_pem
  key_vault_id = var.key_vault.id
}

resource "azurerm_key_vault_secret" "aio_ca_cert_chain" {
  name         = "aio-ca-cert-chain"
  value        = var.aio_ca.ca_cert_chain_pem
  key_vault_id = var.key_vault.id
}

resource "azurerm_key_vault_secret" "aio_root_ca_cert" {
  name         = "aio-root-ca-cert"
  value        = var.aio_ca.root_ca_cert_pem
  key_vault_id = var.key_vault.id
}

locals {
  script_path = "${path.root}/.."
}

resource "terraform_data" "add_customer_managed_configuration" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "${local.script_path}/scripts/apply-manifests.sh"
    environment = {
      TF_CONNECTED_CLUSTER_NAME      = var.connected_cluster_name
      TF_RESOURCE_GROUP_NAME         = var.resource_group_name
      TF_MODULE_PATH                 = local.script_path
      TF_AIO_NAMESPACE               = var.aio_namespace
      TF_SSE_USER_ASSIGNED_CLIENT_ID = var.sse_user_managed_identity.client_id
      TF_KEY_VAULT_NAME              = var.key_vault.name
      TF_AZURE_TENANT_ID             = data.azurerm_subscription.current.tenant_id
      TF_AIO_CONFIGMAP_KEY           = var.customer_managed_trust_settings.configmap_key
      TF_AIO_CONFIGMAP_NAME          = var.customer_managed_trust_settings.configmap_name
      TF_AIO_ISSUER_KIND             = var.customer_managed_trust_settings.issuer_kind
      TF_AIO_ISSUER_NAME             = var.customer_managed_trust_settings.issuer_name
    }
  }

  depends_on = [azurerm_federated_identity_credential.federated_identity_cred_sse_cert_manager]
}

resource "azurerm_federated_identity_credential" "federated_identity_cred_sse_cert_manager" {
  name                = "cert-manager-sse-ficred"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = data.azapi_resource.cluster_oidc_issuer.output.properties.oidcIssuerProfile.issuerUrl
  parent_id           = var.sse_user_managed_identity.id
  subject             = "system:serviceaccount:cert-manager:sa-federated-cred-sse"
}

data "azapi_resource" "cluster_oidc_issuer" {
  name      = var.connected_cluster_name
  parent_id = var.resource_group_id
  type      = "Microsoft.Kubernetes/connectedClusters@2024-12-01-preview"

  response_export_values = ["properties.oidcIssuerProfile.issuerUrl"]
}
