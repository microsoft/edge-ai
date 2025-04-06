<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Terraform IaC

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.2.0 |
| azurerm | >= 4.8.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| sample\_event\_grid\_dataflow | ./modules/event-grid | n/a |
| sample\_event\_hub\_dataflow | ./modules/event-hub | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_custom\_locations | n/a | ```object({ name = string id = string })``` | n/a | yes |
| aio\_dataflow\_profile | n/a | ```object({ id = string })``` | n/a | yes |
| aio\_identity | n/a | ```object({ id = string principal_id = string tenant_id = string client_id = string })``` | n/a | yes |
| aio\_instance | n/a | ```object({ id = string })``` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| asset\_name | The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud. | `string` | `"oven"` | no |
| event\_grid | Values for the existing Event Grid | ```object({ topic_name = string endpoint = string })``` | `null` | no |
| event\_hub | Values for the existing Event Hub namespace and Event Hub | ```object({ namespace_name = string event_hub_name = string })``` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
