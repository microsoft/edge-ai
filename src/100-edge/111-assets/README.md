# IoT Assets Component

This component deploys and manages Kubernetes asset definitions for Edge AI applications. It facilitates the creation of asset types and asset instances that can be utilized across your Edge AI infrastructure.

## Features

- Create and manage asset type definitions
- Deploy asset instances with their properties
- Support for custom Kubernetes manifest deployment via scripts
- Integration with Azure Arc-enabled Kubernetes clusters

## Usage

### Basic Usage

To use this component in your Terraform configuration:

```terraform
module "assets" {
  source = "../../src/100-edge/111-assets/terraform"

  resource_group         = var.resource_group
  location               = var.location

  custom_location_id     = var.custom_location_id
  connected_cluster_name = var.connected_cluster_name

  // Define asset endpoint profile
  asset_endpoint_profiles = [
    {
      name         = "opc-server-name"
      target_address = "opc-server-address"
      endpoint_profile_type  = "endpoint-type"
      method = "string"
      should_enable_opc_asset_discovery = "bool"
      opc_additional_config_string = "string"
    }
  ]

  // Define asset instances
  assets = [
    {
      name         = "machine001"
      display_name = "Machine 001"
      description = "description"
      enabled = true
      documentationUri             = "documentationUri"
      manufacturer                 = "manufacturer"
      manufacturerUri              = "manufacturerUri"
      model                        = "model"
      productCode                  = "productCode"
      hardwareRevision             = "hardwareRevision"
      softwareRevision             = "softwareRevision"
      serialNumber                 = "serialNumber"
      assetEndpointProfileRef      = "opc-server-name"
      defaultDatasetsConfiguration = "{\"samplingInterval\":500,\"queueSize\":1,\"publishingInterval\":1000}"
      datasets = [
        {
            name = "some random datasets name"
            dataPoints = [
            {
                name       = "Temperature"
                dataSource = "ns=3;s=FastUInt10"
                observabilityMode      = "None"
                dataPointConfiguration = "{\"samplingInterval\":500,\"queueSize\":1}"
            }]
        }
      ]
    }
  ]

```

## Requirements

- Azure Arc-enabled Kubernetes cluster
- Terraform >= 1.9.8
- Azure CLI with `connectedk8s` extension
