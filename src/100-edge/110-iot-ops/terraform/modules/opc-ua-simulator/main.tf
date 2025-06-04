/**
 * # Azure IoT Operations OPC UA Simulator
 *
 * Deploy and configure the OPC UA Simulator
 *
 */

module "aio_apply_scripts_pre_instance" {
  source = "../apply-scripts"

  aio_namespace = "azure-iot-operations"
  scripts = [{
    files       = ["apply-simulator.sh"]
    environment = {}
  }]
  connected_cluster_name = var.connected_cluster_name
  resource_group_name    = var.resource_group.name
}
