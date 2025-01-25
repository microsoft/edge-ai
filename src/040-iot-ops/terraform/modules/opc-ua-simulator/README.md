<!-- BEGIN_TF_DOCS -->
# Azure IoT Operations OPC UA Simulator

Deploy and configure the OPC UA Simulator

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

- azapi (2.1.0)

## Providers

The following providers are used by this module:

- azapi (2.1.0)

## Resources

The following resources are used by this module:

- [azapi_resource.asset](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/resources/resource) (resource)
- [azapi_resource.asset_endpoint](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/resources/resource) (resource)

## Modules

The following Modules are called:

### aio\_apply\_scripts\_pre\_instance

Source: ../apply-scripts

Version:

## Required Inputs

The following input variables are required:

### connected\_cluster\_name

Description: The name of the connected cluster to deploy Azure IoT Operations to

Type: `string`

### custom\_location\_id

Description: The id of the custom location to deploy Azure IoT Operations to

Type: `string`

### location

Description: Location for all resources in this module

Type: `string`

### resource\_group

Description: Name and ID of the pre-existing resource group in which to create resources

Type:

```hcl
object({
    id   = string
    name = string
  })
```

## Outputs

The following outputs are exported:

### asset\_name

Description: n/a
<!-- END_TF_DOCS -->
