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

resource "azapi_resource" "asset_endpoint" {
  type      = "Microsoft.DeviceRegistry/assetEndpointProfiles@2024-11-01"
  name      = "opc-ua-connector-0"
  parent_id = var.resource_group.id
  body = {
    location = var.location
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = {
      targetAddress       = "opc.tcp://opcplc-000000:50000"
      endpointProfileType = "Microsoft.OpcUa"
      authentication = {
        method = "Anonymous"
      }
    }
  }
}

resource "azapi_resource" "asset" {
  type      = "Microsoft.DeviceRegistry/assets@2024-11-01"
  name      = "oven"
  parent_id = var.resource_group.id
  body = {
    location = var.location
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = {
      displayName             = "oven"
      assetEndpointProfileRef = azapi_resource.asset_endpoint.name
      description             = "an oven is essential for baking a wide variety of products"
      enabled                 = true
      externalAssetId         = "32faab3f-88e8-4f38-b901-e175dde50c28"
      manufacturer            = "http://asset.oven.contoso"
      manufacturerUri         = "http://oven.asset.contoso"
      model                   = "Mymodel"
      productCode             = "12345C"
      hardwareRevision        = "http://docs.oven.asset.contoso"
      softwareRevision        = "1.1"
      serialNumber            = "12345"
      documentationUri        = "http://docs.oven.asset.contoso"
      datasets = [
        {
          name = "some random datasets name"
          dataPoints = [
            {
              name                   = "Temperature"
              dataSource             = "ns=3;s=FastUInt100"
              dataPointConfiguration = "{\"samplingInterval\":500,\"queueSize\":1}"
              observabilityMode      = "None"
            },
            {
              name                   = "FillWeight"
              dataSource             = "ns=3;s=FastUInt1004"
              dataPointConfiguration = "{\"samplingInterval\":500,\"queueSize\":1}"
              observabilityMode      = "None"
            },
            {
              name                   = "EnergyUse"
              dataSource             = "ns=3;s=FastUInt1005"
              dataPointConfiguration = "{\"samplingInterval\":500,\"queueSize\":1}"
              observabilityMode      = "None"
            }
          ]
        }
      ]
      defaultDatasetsConfiguration = "{\"publishingInterval\":1000,\"samplingInterval\":500,\"queueSize\":1}"
    }
  }
}
