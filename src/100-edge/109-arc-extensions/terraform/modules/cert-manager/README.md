<!-- BEGIN_TF_DOCS -->
# cert-manager Extension Module

Deploys the cert-manager extension for Arc-enabled Kubernetes clusters.

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name    | Version |
|---------|---------|
| azurerm | n/a     |

## Resources

| Name                                                                                                                                                                      | Type     |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| [azurerm_arc_kubernetes_cluster_extension.cert_manager](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) | resource |

## Inputs

| Name                        | Description                                             | Type                                                                                                                                                                                                                                       | Default | Required |
|-----------------------------|---------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|:--------:|
| arc\_connected\_cluster\_id | The resource ID of the Arc-connected Kubernetes cluster | `string`                                                                                                                                                                                                                                   | n/a     |   yes    |
| cert\_manager\_extension    | cert-manager extension configuration object             | ```object({ enabled = optional(bool) version = optional(string) train = optional(string) auto_upgrade_minor_version = optional(bool) agent_operation_timeout_in_minutes = optional(number) global_telemetry_enabled = optional(bool) })``` | n/a     |   yes    |

## Outputs

| Name          | Description                                         |
|---------------|-----------------------------------------------------|
| cert\_manager | Self-contained cert-manager object                  |
| extension     | The cert-manager extension id and name as an object |
<!-- END_TF_DOCS -->
