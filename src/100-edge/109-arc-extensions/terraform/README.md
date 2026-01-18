<!-- BEGIN_TF_DOCS -->
# Arc Extensions

Deploys foundational Arc-enabled Kubernetes cluster extensions including
cert-manager and Azure Container Storage (ACSA).

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm   | >= 4.8.0        |

## Modules

| Name                          | Source                      | Version |
|-------------------------------|-----------------------------|---------|
| cert\_manager\_extension      | ./modules/cert-manager      | n/a     |
| container\_storage\_extension | ./modules/container-storage | n/a     |

## Inputs

| Name                    | Description                                                                           | Type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | Default                                                                                                                                                                                                                                                                                                                                                                                                                                 | Required |
|-------------------------|---------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------:|
| arc\_connected\_cluster | Arc-connected Kubernetes cluster object containing id, name, and location             | ```object({ id = string name = string location = string })```                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                     |   yes    |
| arc\_extensions         | Combined configuration object for Arc extensions (cert-manager and container storage) | ```object({ cert_manager_extension = optional(object({ enabled = optional(bool) version = optional(string) train = optional(string) auto_upgrade_minor_version = optional(bool) agent_operation_timeout_in_minutes = optional(number) global_telemetry_enabled = optional(bool) })) container_storage_extension = optional(object({ enabled = optional(bool) version = optional(string) train = optional(string) auto_upgrade_minor_version = optional(bool) disk_storage_class = optional(string) fault_tolerance_enabled = optional(bool) disk_mount_point = optional(string) })) })``` | ```{ "cert_manager_extension": { "agent_operation_timeout_in_minutes": 20, "auto_upgrade_minor_version": false, "enabled": true, "global_telemetry_enabled": true, "train": "stable", "version": "0.7.0" }, "container_storage_extension": { "auto_upgrade_minor_version": false, "disk_mount_point": "/mnt", "disk_storage_class": "", "enabled": true, "fault_tolerance_enabled": false, "train": "stable", "version": "2.6.0" } }``` |    no    |

## Outputs

| Name                                | Description                                                                                          |
|-------------------------------------|------------------------------------------------------------------------------------------------------|
| cert\_manager\_extension            | Self-contained cert\_manager object (id, name, enabled, version, train) or null if not deployed      |
| cert\_manager\_extension\_id        | The resource ID of the cert-manager extension.                                                       |
| cert\_manager\_extension\_name      | The name of the cert-manager extension.                                                              |
| container\_storage\_extension       | Self-contained container\_storage object (id, name, enabled, version, train) or null if not deployed |
| container\_storage\_extension\_id   | The resource ID of the Azure Container Storage extension.                                            |
| container\_storage\_extension\_name | The name of the Azure Container Storage extension.                                                   |
<!-- END_TF_DOCS -->
