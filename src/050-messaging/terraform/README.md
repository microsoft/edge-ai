<!-- BEGIN_TF_DOCS -->
# Messaging

Sets up messaging infrastructure and includes deploying a sample
Azure IoT Operations Dataflow to send and receive data from edge to cloud.

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

- azapi (>= 2.1.0)

- azurerm (>= 4.8.0)

## Providers

The following providers are used by this module:

- azapi (>= 2.1.0)

- azurerm (>= 4.8.0)

- terraform

## Resources

The following resources are used by this module:

- [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)
- [azapi_resource.custom_locations](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) (data source)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) (data source)

## Modules

The following Modules are called:

### event\_hubs

Source: ./modules/event-hubs

Version:

### sample\_event\_hub\_dataflow

Source: ./modules/event-hub-dataflow

Version:

## Required Inputs

The following input variables are required:

### environment

Description: Environment for all resources in this module: dev, test, or prod

Type: `string`

### resource\_prefix

Description: Prefix for all resources in this module

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### asset\_name

Description: The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud.

Type: `string`

Default: `"oven"`

### connected\_cluster\_name

Description: The name of the Azure Arc connected cluster resource for Azure IoT Operations. (Otherwise, '{var.resource\_prefix}-arc')

Type: `string`

Default: `null`

### custom\_locations\_name

Description: The name of the Custom Locations resource used by Azure IoT Operations. (Otherwise, '{var.connected\_cluster\_name}-cl')

Type: `string`

Default: `null`

### instance

Description: Instance identifier for naming resources: 001, 002, etc...

Type: `string`

Default: `"001"`

### iot\_ops\_instance\_name

Description: The name of the Azure IoT Operations Instance resource. (Otherwise, '{var.connected\_cluster\_name}-ops-instance')

Type: `string`

Default: `null`

### iot\_ops\_k8s\_extension\_name

Description: The name of the Azure Arc Extension for Azure IoT Operations, needed to assign permissions. (Should be changed to a UAMI)

Type: `string`

Default: `"iot-ops"`

### resource\_group\_name

Description: The name for the resource group. (Otherwise, 'rg-{var.resource\_prefix}-{var.environment}-{var.instance}')

Type: `string`

Default: `null`
<!-- END_TF_DOCS -->
