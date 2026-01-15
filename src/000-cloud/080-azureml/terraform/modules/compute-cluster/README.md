<!-- BEGIN_TF_DOCS -->
# Azure Machine Learning Compute Cluster Module

This module creates an Azure ML compute cluster for ML training workloads

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm   | >= 4.51.0       |

## Providers

| Name    | Version   |
|---------|-----------|
| azurerm | >= 4.51.0 |

## Resources

| Name                                                                                                                                                              | Type     |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| [azurerm_machine_learning_compute_cluster.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/machine_learning_compute_cluster) | resource |

## Inputs

| Name                                      | Description                                                                                                        | Type                                                  | Default | Required |
|-------------------------------------------|--------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------|---------|:--------:|
| description                               | Description of the compute cluster.                                                                                | `string`                                              | n/a     |   yes    |
| environment                               | The environment for the deployment.                                                                                | `string`                                              | n/a     |   yes    |
| instance                                  | Instance identifier for the deployment.                                                                            | `string`                                              | n/a     |   yes    |
| location                                  | Azure region where the cluster will be created.                                                                    | `string`                                              | n/a     |   yes    |
| machine\_learning\_workspace\_id          | Resource ID of the Machine Learning workspace.                                                                     | `string`                                              | n/a     |   yes    |
| max\_node\_count                          | Maximum number of nodes in compute cluster for auto-scaling.                                                       | `number`                                              | n/a     |   yes    |
| min\_node\_count                          | Minimum number of nodes in compute cluster for auto-scaling.                                                       | `number`                                              | n/a     |   yes    |
| name                                      | Name of the compute cluster.                                                                                       | `string`                                              | n/a     |   yes    |
| node\_public\_ip\_enabled                 | Whether the compute cluster nodes will have public IPs. Should be false for private endpoint scenarios.            | `bool`                                                | n/a     |   yes    |
| resource\_prefix                          | Prefix for all resource names.                                                                                     | `string`                                              | n/a     |   yes    |
| scale\_down\_nodes\_after\_idle\_duration | Time to wait before scaling down idle nodes (format: PT{minutes}M).                                                | `string`                                              | n/a     |   yes    |
| snet\_azureml                             | Subnet for the Azure ML compute cluster.                                                                           | ```object({ id = string name = optional(string) })``` | n/a     |   yes    |
| ssh\_public\_access\_enabled              | Whether to enable public SSH port access to compute cluster nodes. Should be false for private endpoint scenarios. | `bool`                                                | n/a     |   yes    |
| vm\_priority                              | VM priority for compute cluster nodes (Dedicated or LowPriority).                                                  | `string`                                              | n/a     |   yes    |
| vm\_size                                  | VM size for compute cluster nodes.                                                                                 | `string`                                              | n/a     |   yes    |

## Outputs

| Name                   | Description                                                       |
|------------------------|-------------------------------------------------------------------|
| compute\_cluster       | Azure Machine Learning compute cluster object.                    |
| compute\_cluster\_id   | The ID of the compute cluster.                                    |
| compute\_cluster\_name | The name of the compute cluster.                                  |
| principal\_id          | The Principal ID of the System Assigned Managed Service Identity. |
| tenant\_id             | The Tenant ID of the System Assigned Managed Service Identity.    |
<!-- END_TF_DOCS -->
