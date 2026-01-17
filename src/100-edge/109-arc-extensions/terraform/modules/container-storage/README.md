<!-- BEGIN_TF_DOCS -->
# Azure Container Storage Extension Module

Deploys the Azure Container Storage (ACSA) extension for Arc-enabled Kubernetes clusters.

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name    | Version |
|---------|---------|
| azurerm | n/a     |

## Resources

| Name                                                                                                                                                                           | Type     |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| [azurerm_arc_kubernetes_cluster_extension.container_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) | resource |

## Inputs

| Name                          | Description                                             | Type                                                                                                                                                                                                                                                          | Default | Required |
|-------------------------------|---------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|:--------:|
| arc\_connected\_cluster\_id   | The resource ID of the Arc-connected Kubernetes cluster | `string`                                                                                                                                                                                                                                                      | n/a     |   yes    |
| container\_storage\_extension | container-storage extension configuration object        | ```object({ enabled = optional(bool) version = optional(string) train = optional(string) auto_upgrade_minor_version = optional(bool) disk_storage_class = optional(string) fault_tolerance_enabled = optional(bool) disk_mount_point = optional(string) })``` | n/a     |   yes    |

## Outputs

| Name               | Description                                              |
|--------------------|----------------------------------------------------------|
| container\_storage | Self-contained container\_storage object                 |
| extension          | The container storage extension id and name as an object |
<!-- END_TF_DOCS -->
