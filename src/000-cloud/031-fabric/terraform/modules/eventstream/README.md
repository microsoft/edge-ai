<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Terraform IaC

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0.0 |
| fabric | 0.1.0-rc.2 |

## Providers

| Name | Version |
|------|---------|
| fabric | 0.1.0-rc.2 |

## Resources

| Name | Type |
|------|------|
| [fabric_eventstream.this](https://registry.terraform.io/providers/microsoft/fabric/0.1.0-rc.2/docs/resources/eventstream) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| eventhub\_endpoint | The Azure Eventhub endpoint to use as a source | `string` | n/a | yes |
| eventstream\_description | The description of the event stream | `string` | n/a | yes |
| eventstream\_display\_name | The display name of the event stream | `string` | n/a | yes |
| lakehouse\_id | The ID of the lakehouse where data will be stored | `string` | n/a | yes |
| workspace\_id | The ID of the workspace where the event stream will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| eventstream\_id | The ID of the created event stream |
| eventstream\_name | The name of the created event stream |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
