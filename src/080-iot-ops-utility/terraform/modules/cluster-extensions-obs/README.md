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
| [azurerm_kubernetes_cluster_extension.container_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_extension) | resource |
| [azurerm_kubernetes_cluster_extension.container_metrics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_extension) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| azure\_monitor\_workspace\_name | The name of the Azure Monitor resource. | `string` | n/a | yes |
| grafana\_name | The name of the Azure Managed Grafana resource. | `string` | n/a | yes |
| log\_analytics\_workspace\_name | The name of the Azure Log Analytics resource. | `string` | n/a | yes |
| resource\_group\_id | The id of the Azure Resource Group. | `string` | n/a | yes |
| arc\_connected\_cluster\_id | The id of the Azure Arc connected cluster resource for Azure IoT Operations. | `string` | `null` | no |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
