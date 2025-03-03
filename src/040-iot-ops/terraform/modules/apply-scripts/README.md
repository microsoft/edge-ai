<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Apply Scripts

Sets up an `az connectedk8s proxy`, if needed,  and then runs the corresponding
scripts passed into this module.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name | Version |
|------|---------|
| terraform | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_data.apply_scripts](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_namespace | Azure IoT Operations namespace | `string` | n/a | yes |
| connected\_cluster\_name | The name of the connected cluster to deploy Azure IoT Operations to | `string` | n/a | yes |
| resource\_group\_name | The name for the resource group. | `string` | n/a | yes |
| scripts | List of scripts to apply, the objects will be merged together to make one scripting call | ```list( object({ files = list(string) environment = map(any) }) )``` | n/a | yes |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
