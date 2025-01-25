<!-- BEGIN_TF_DOCS -->
# Apply Scripts

Sets up an `az connectedk8s proxy`, if needed,  and then runs the corresponding
scripts passed into this module.

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

## Providers

The following providers are used by this module:

- terraform

## Resources

The following resources are used by this module:

- [terraform_data.apply_scripts](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)

## Required Inputs

The following input variables are required:

### aio\_namespace

Description: Azure IoT Operations namespace

Type: `string`

### connected\_cluster\_name

Description: The name of the connected cluster to deploy Azure IoT Operations to

Type: `string`

### resource\_group\_name

Description: Name of the pre-existing resource group in which to create resources

Type: `string`

### scripts

Description: List of scripts to apply, the objects will be merged together to make one scripting call

Type:

```hcl
list(
    object({
      files       = list(string)
      environment = map(any)
    })
  )
```
<!-- END_TF_DOCS -->
