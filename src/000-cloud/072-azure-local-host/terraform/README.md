<!-- BEGIN_TF_DOCS -->
# Azure Local Host

Creates Azure Stack HCI (Azure Local) cluster resources.

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |
| azapi     | >= 2.3.0        |
| azurerm   | >= 4.8.0        |

## Providers

| Name    | Version  |
|---------|----------|
| azapi   | >= 2.3.0 |
| azurerm | >= 4.8.0 |
| tls     | n/a      |

## Resources

| Name                                                                                                                              | Type        |
|-----------------------------------------------------------------------------------------------------------------------------------|-------------|
| [azapi_resource.agent_pool](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource)                   | resource    |
| [azapi_resource.connected_cluster](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource)            | resource    |
| [azapi_resource.provisioned_cluster_instance](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource    |
| [tls_private_key.cluster_ssh](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key)            | resource    |
| [azapi_resource.logical_network](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/resource)           | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name                                    | Description                                                                                                                                           | Type                                                                                                                                           | Default                                                                              | Required |
|-----------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------|:--------:|
| custom\_locations\_oid                  | Resource ID of the custom location for the Azure Stack HCI cluster.                                                                                   | `string`                                                                                                                                       | n/a                                                                                  |   yes    |
| environment                             | Environment for all resources in this module: dev, test, or prod.                                                                                     | `string`                                                                                                                                       | n/a                                                                                  |   yes    |
| location                                | Location for all resources in this module.                                                                                                            | `string`                                                                                                                                       | n/a                                                                                  |   yes    |
| logical\_network\_name                  | Name of the logical network for the Kubernetes cluster.                                                                                               | `string`                                                                                                                                       | n/a                                                                                  |   yes    |
| logical\_network\_resource\_group\_name | Resource group name containing the logical network for the Kubernetes cluster.                                                                        | `string`                                                                                                                                       | n/a                                                                                  |   yes    |
| resource\_group                         | Resource group object containing name and id where resources will be deployed                                                                         | ```object({ name = string id = string })```                                                                                                    | n/a                                                                                  |   yes    |
| resource\_prefix                        | Prefix for all resources in this module.                                                                                                              | `string`                                                                                                                                       | n/a                                                                                  |   yes    |
| aad\_profile                            | Azure Active Directory profile configuration for the Kubernetes cluster. If enable\_azure\_rbac is false, admin\_group\_object\_ids must be provided. | ```object({ admin_group_object_ids = optional(list(string), []) enable_azure_rbac = bool tenant_id = optional(string) })```                    | ```{ "admin_group_object_ids": [], "enable_azure_rbac": true, "tenant_id": null }``` |    no    |
| additional\_nodepools                   | Additional node pools to create for the cluster (Otherwise, none).                                                                                    | ```list(object({ name = string count = number vmSize = string osType = optional(string, "Linux") osSKU = optional(string, "CBLMariner") }))``` | `[]`                                                                                 |    no    |
| azure\_hybrid\_benefit                  | Azure Hybrid Benefit setting (Otherwise, 'NotApplicable').                                                                                            | `string`                                                                                                                                       | `"NotApplicable"`                                                                    |    no    |
| control\_plane\_count                   | Number of control plane nodes (Otherwise, 1).                                                                                                         | `number`                                                                                                                                       | `1`                                                                                  |    no    |
| control\_plane\_ip                      | IP address for the Kubernetes control plane endpoint (Otherwise, dynamically assigned).                                                               | `string`                                                                                                                                       | `null`                                                                               |    no    |
| control\_plane\_vm\_size                | VM size for control plane nodes (Otherwise, 'Standard\_A4\_v2').                                                                                      | `string`                                                                                                                                       | `"Standard_A4_v2"`                                                                   |    no    |
| instance                                | Instance identifier for naming resources: 001, 002, etc.                                                                                              | `string`                                                                                                                                       | `"001"`                                                                              |    no    |
| kubernetes\_version                     | Kubernetes version for the cluster (Otherwise, latest stable version).                                                                                | `string`                                                                                                                                       | `null`                                                                               |    no    |
| load\_balancer\_count                   | Number of load balancers for the cluster (Otherwise, 0).                                                                                              | `number`                                                                                                                                       | `0`                                                                                  |    no    |
| nfs\_csi\_driver\_enabled               | Enable NFS CSI driver for persistent storage (Otherwise, false).                                                                                      | `bool`                                                                                                                                         | `false`                                                                              |    no    |
| node\_pool\_count                       | Number of worker nodes in the default node pool (Otherwise, 1).                                                                                       | `number`                                                                                                                                       | `1`                                                                                  |    no    |
| node\_pool\_vm\_size                    | VM size for worker nodes (Otherwise, 'Standard\_D8s\_v3').                                                                                            | `string`                                                                                                                                       | `"Standard_D8s_v3"`                                                                  |    no    |
| pod\_cidr                               | CIDR range for Kubernetes pods (Otherwise, '10.244.0.0/16').                                                                                          | `string`                                                                                                                                       | `"10.244.0.0/16"`                                                                    |    no    |
| smb\_csi\_driver\_enabled               | Enable SMB CSI driver for persistent storage (Otherwise, false).                                                                                      | `bool`                                                                                                                                         | `false`                                                                              |    no    |
| ssh\_public\_key                        | SSH public key for Linux nodes (Otherwise, generated).                                                                                                | `string`                                                                                                                                       | `null`                                                                               |    no    |

## Outputs

| Name        | Description                                                 |
|-------------|-------------------------------------------------------------|
| cluster\_id | Resource ID of the provisioned Kubernetes cluster instance. |
| id          | Resource ID of the Kubernetes connected cluster.            |
| location    | Location of the Kubernetes connected cluster.               |
| name        | Name of the Kubernetes connected cluster.                   |
<!-- END_TF_DOCS -->
