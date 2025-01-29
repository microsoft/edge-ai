<!-- BEGIN_TF_DOCS -->
# Azure IoT Operations Dataflow sample

Provisions the ARM based data flow endpoint and data flow, requires Asset

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

- azapi (2.1.0)

## Providers

The following providers are used by this module:

- azapi (2.1.0)

## Resources

The following resources are used by this module:

- [azapi_resource.data_flow](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/resources/resource) (resource)
- [azapi_resource.data_flow_endpoint_to_event_hub](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/resources/resource) (resource)
- [azapi_resource.data_flow_profile](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/data-sources/resource) (data source)
- [azapi_resource.instance](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/data-sources/resource) (data source)

## Required Inputs

The following input variables are required:

### aio\_instance\_name

Description: The name of the Azure IoT Operations instance

Type: `string`

### aio\_uami\_client\_id

Description: Client ID of the User Assigned Managed Identity for the Azure IoT Operations instance

Type: `string`

### aio\_uami\_tenant\_id

Description: Tenant ID of the User Assigned Managed Identity for the Azure IoT Operations instance

Type: `string`

### asset\_name

Description: The name of the Event Hub namespace

Type: `string`

### custom\_location\_id

Description: The id of the custom location to deploy Azure IoT Operations to

Type: `string`

### event\_hub

Description: Values for the existing Event Hub namespace and Event Hub

Type:

```hcl
object({
    namespace_name = string
    event_hub_name = string
  })
```

### resource\_group\_id

Description: The id of the pre-existing resource group in which to create resources

Type: `string`

### resource\_prefix

Description: Prefix for all resources in this module

Type: `string`
<!-- END_TF_DOCS -->
