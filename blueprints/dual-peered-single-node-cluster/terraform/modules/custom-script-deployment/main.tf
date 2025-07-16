/**
 * # Custom Script Deployment Module (Refactored)
 *
 * This module handles deployment of custom scripts to VMs using Azure VM extensions.
 * Scripts are stored in separate files for better maintainability and readability.
 */

locals {
  # Base64 encode certificate files for inclusion in the script
  server_root_ca_cert         = base64encode(file("${path.module}/../../../certs/l4-server-root-ca.crt"))
  server_intermediate_ca_cert = base64encode(file("${path.module}/../../../certs/l4-server-intermediate-ca.crt"))
  server_leaf_ca_cert         = base64encode(file("${path.module}/../../../certs/l4-server-leaf-ca.crt"))
  server_leaf_ca_key          = base64encode(file("${path.module}/../../../certs/l4-server-leaf-ca.key"))

  client_root_ca_cert         = base64encode(file("${path.module}/../../../certs/l4-client-root-ca.crt"))
  client_intermediate_ca_cert = base64encode(file("${path.module}/../../../certs/l4-client-intermediate-ca.crt"))
  client_leaf_ca_cert         = base64encode(file("${path.module}/../../../certs/l4-client-leaf-ca.crt"))
  client_leaf_ca_key          = base64encode(file("${path.module}/../../../certs/l4-client-leaf-ca.key"))

  # Base64 encode Kubernetes manifests
  server_central_mqtt_broker_authentication = base64encode(file("${path.module}/../../../scripts/server-central-mqtt-broker-authentication.yaml"))
  server_central_mqtt_broker_listener       = base64encode(file("${path.module}/../../../scripts/server-central-mqtt-broker-listener.yaml"))
  client_technology_mqtt_broker_listener    = base64encode(file("${path.module}/../../../scripts/client-technology-mqtt-broker-listener.yaml"))
  client_technology_mqtt_endpoint           = base64encode(file("${path.module}/../../../scripts/client-technology-mqtt-endpoint.yaml"))
  server_central_mqtt_endpoint_cert_auth    = base64encode(file("${path.module}/../../../scripts/server-central-mqtt-endpoint-cert-auth.yaml"))
  technology_central_route_cert_auth        = base64encode(file("${path.module}/../../../scripts/technology-central-route-cert-auth.yaml"))

  # Generate scripts using templatefile() for clean separation of concerns
  server_central_script = templatefile("${path.module}/scripts/server-central.sh", {
    server_root_ca_cert                       = local.server_root_ca_cert
    server_intermediate_ca_cert               = local.server_intermediate_ca_cert
    server_leaf_ca_cert                       = local.server_leaf_ca_cert
    server_leaf_ca_key                        = local.server_leaf_ca_key
    client_root_ca_cert                       = local.client_root_ca_cert
    server_central_mqtt_broker_authentication = local.server_central_mqtt_broker_authentication
    server_central_mqtt_broker_listener       = local.server_central_mqtt_broker_listener
  })

  client_technology_script = templatefile("${path.module}/scripts/client-technology.sh", {
    client_root_ca_cert                    = local.client_root_ca_cert
    client_intermediate_ca_cert            = local.client_intermediate_ca_cert
    client_leaf_ca_cert                    = local.client_leaf_ca_cert
    client_leaf_ca_key                     = local.client_leaf_ca_key
    server_root_ca_cert                    = local.server_root_ca_cert
    client_technology_mqtt_broker_listener = local.client_technology_mqtt_broker_listener
    client_technology_mqtt_endpoint        = local.client_technology_mqtt_endpoint
    server_central_mqtt_endpoint_cert_auth = local.server_central_mqtt_endpoint_cert_auth
    technology_central_route_cert_auth     = local.technology_central_route_cert_auth
  })
}

// Deploy server-central script to VM via Custom Script Extension
resource "azurerm_virtual_machine_extension" "server_central_deployment" {
  count = var.should_deploy_server_central_script ? 1 : 0

  name                        = "server-central-script-deployment"
  virtual_machine_id          = var.server_vm_id
  publisher                   = "Microsoft.Azure.Extensions"
  type                        = "CustomScript"
  type_handler_version        = "2.1"
  automatic_upgrade_enabled   = false
  auto_upgrade_minor_version  = false
  failure_suppression_enabled = false

  protected_settings = jsonencode({
    script = base64encode(local.server_central_script)
  })
}

// Deploy client-technology script to VM via Custom Script Extension
resource "azurerm_virtual_machine_extension" "client_technology_deployment" {
  count = var.should_deploy_client_technology_script ? 1 : 0

  name                        = "client-technology-script-deployment"
  virtual_machine_id          = var.client_vm_id
  publisher                   = "Microsoft.Azure.Extensions"
  type                        = "CustomScript"
  type_handler_version        = "2.1"
  automatic_upgrade_enabled   = false
  auto_upgrade_minor_version  = false
  failure_suppression_enabled = false

  protected_settings = jsonencode({
    script = base64encode(local.client_technology_script)
  })
}
