/**
 * # cert-manager Extension Module
 *
 * Deploys the cert-manager extension for Arc-enabled Kubernetes clusters.
 */

resource "azurerm_arc_kubernetes_cluster_extension" "cert_manager" {
  name           = "arc-cert-manager"
  cluster_id     = var.arc_connected_cluster_id
  extension_type = "microsoft.certmanagement"
  identity {
    type = "SystemAssigned"
  }
  version           = var.cert_manager_extension.version
  release_train     = var.cert_manager_extension.train
  release_namespace = "cert-manager"
  configuration_settings = {
    "AgentOperationTimeoutInMinutes" = tostring(var.cert_manager_extension.agent_operation_timeout_in_minutes)
    "global.telemetry.enabled"       = var.cert_manager_extension.global_telemetry_enabled
  }
}
