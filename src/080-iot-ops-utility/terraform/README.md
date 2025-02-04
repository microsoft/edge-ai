<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# IoT Ops Utilities Extensions

Creates resources needed for additional utilities and features.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.2.0 |
| azurerm | >= 4.8.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| cluster\_extensions\_obs | ./modules/cluster-extensions-obs | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_azure\_managed\_grafana | n/a | ```object({ id = string })``` | n/a | yes |
| aio\_azure\_monitor\_workspace | n/a | ```object({ id = string })``` | n/a | yes |
| aio\_log\_analytics\_workspace | n/a | ```object({ id = string })``` | n/a | yes |
| arc\_connected\_cluster | n/a | ```object({ name = string id = string location = string })``` | n/a | yes |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
