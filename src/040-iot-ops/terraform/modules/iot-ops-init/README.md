<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure IoT Enablement Module

Deploys resources necessary to enable Azure IoT Operations (AIO) and creates an AIO instance.

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
| [azurerm_arc_kubernetes_cluster_extension.container_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) | resource |
| [azurerm_arc_kubernetes_cluster_extension.open_service_mesh](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) | resource |
| [azurerm_arc_kubernetes_cluster_extension.platform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) | resource |
| [azurerm_arc_kubernetes_cluster_extension.secret_store](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_platform\_config | Install cert-manager and trust-manager extensions | ```object({ install_cert_manager = bool install_trust_manager = bool })``` | n/a | yes |
| arc\_connected\_cluster\_id | The resource ID of the connected cluster to deploy Azure IoT Operations Platform to | `string` | n/a | yes |
| edge\_storage\_accelerator | n/a | ```object({ version = string train = string diskStorageClass = string faultToleranceEnabled = bool })``` | n/a | yes |
| open\_service\_mesh | n/a | ```object({ version = string train = string })``` | n/a | yes |
| platform | n/a | ```object({ version = string train = string })``` | n/a | yes |
| secret\_sync\_controller | n/a | ```object({ version = string train = string })``` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| platform\_cluster\_extension\_id | n/a |
| secret\_store\_extension\_cluster\_id | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
