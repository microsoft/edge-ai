<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Cluster Extensions for Observability

Creates the cluster extensions required to expose cluster and container metrics.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_arc_kubernetes_cluster_extension.container_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) | resource |
| [azurerm_arc_kubernetes_cluster_extension.container_metrics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_azure\_managed\_grafana | n/a | ```object({ id = string })``` | n/a | yes |
| aio\_azure\_monitor\_workspace | n/a | ```object({ id = string })``` | n/a | yes |
| aio\_log\_analytics\_workspace | n/a | ```object({ id = string })``` | n/a | yes |
| arc\_connected\_cluster | n/a | ```object({ id = string })``` | n/a | yes |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
