<!-- BEGIN_TF_DOCS -->
# Arc Inference Cluster Integration Module

Deploys Azure Machine Learning extension on Arc-enabled Kubernetes cluster
and attaches it to Azure ML workspace. This task adds base
role assignments (Reader, Kubernetes Extension Contributor, Cluster Admin)
dependent on extension deployment completion.

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |
| azapi     | >= 2.3.0        |
| azurerm   | >= 4.51.0       |

## Providers

| Name    | Version   |
|---------|-----------|
| azapi   | >= 2.3.0  |
| azurerm | >= 4.51.0 |

## Resources

| Name                                                                                                                                                                 | Type        |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [azapi_resource.kubernetes_compute](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource)                                              | resource    |
| [azurerm_arc_kubernetes_cluster_extension.azureml](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) | resource    |
| [azurerm_federated_identity_credential.ml_workload](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential)   | resource    |
| [azurerm_role_assignment.cluster_admin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment)                             | resource    |
| [azurerm_role_assignment.extension_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment)                     | resource    |
| [azurerm_role_assignment.reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment)                                    | resource    |
| [azurerm_role_assignment.relay_owner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment)                               | resource    |
| [azapi_resource.arc_oidc](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/resource)                                                     | data source |
| [azapi_resource_list.relay_namespaces](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/resource_list)                                   | data source |

## Inputs

| Name                                    | Description                                                                                                                                  | Type                                                                                                                                                          | Default | Required |
|-----------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|:--------:|
| cluster\_id                             | Resource ID of Arc-enabled connected cluster                                                                                                 | `string`                                                                                                                                                      | n/a     |   yes    |
| cluster\_name                           | Name of the Arc-enabled connected cluster                                                                                                    | `string`                                                                                                                                                      | n/a     |   yes    |
| cluster\_purpose                        | Purpose of cluster: DevTest, DenseProd, or FastProd                                                                                          | `string`                                                                                                                                                      | n/a     |   yes    |
| cluster\_resource\_group\_id            | Resource group ID containing the Arc connected cluster. Otherwise derived from cluster\_id.                                                  | `string`                                                                                                                                                      | n/a     |   yes    |
| compute\_target\_name                   | Name of the Arc compute target. Otherwise, 'arc-compute-{resource\_prefix}-{environment}-{instance}'                                         | `string`                                                                                                                                                      | n/a     |   yes    |
| default\_instance\_type                 | Default instance type for the Kubernetes compute.                                                                                            | `string`                                                                                                                                                      | n/a     |   yes    |
| description                             | Description for the Arc integration compute target.                                                                                          | `string`                                                                                                                                                      | n/a     |   yes    |
| disable\_local\_auth                    | Whether to disable local authentication for the Arc integration compute target.                                                              | `bool`                                                                                                                                                        | n/a     |   yes    |
| enable\_inference                       | Whether to enable inference workloads on the cluster                                                                                         | `bool`                                                                                                                                                        | n/a     |   yes    |
| enable\_training                        | Whether to enable training workloads on the cluster                                                                                          | `bool`                                                                                                                                                        | n/a     |   yes    |
| environment                             | Environment for the deployment                                                                                                               | `string`                                                                                                                                                      | n/a     |   yes    |
| extension\_instance\_release\_train     | Extension instance release train for Azure ML extension.                                                                                     | `string`                                                                                                                                                      | n/a     |   yes    |
| extension\_name                         | Name of the Azure ML extension                                                                                                               | `string`                                                                                                                                                      | n/a     |   yes    |
| inference\_router\_ha                   | Whether to enable high availability for inference router                                                                                     | `bool`                                                                                                                                                        | n/a     |   yes    |
| inference\_router\_service\_type        | Service type for inference router: LoadBalancer, NodePort, or ClusterIP                                                                      | `string`                                                                                                                                                      | n/a     |   yes    |
| instance                                | Instance identifier for the deployment                                                                                                       | `string`                                                                                                                                                      | n/a     |   yes    |
| instance\_types                         | Instance types configuration for Kubernetes compute. Key is the instance type name, value contains nodeSelector and resource specifications. | ```map(object({ nodeSelector = optional(map(string)) resources = optional(object({ requests = optional(map(string)) limits = optional(map(string)) })) }))``` | n/a     |   yes    |
| kubernetes\_namespace                   | Kubernetes namespace for ML workloads. Otherwise, 'azureml'.                                                                                 | `string`                                                                                                                                                      | n/a     |   yes    |
| location                                | Location for all resources in this module                                                                                                    | `string`                                                                                                                                                      | n/a     |   yes    |
| machine\_learning\_workspace\_id        | Resource ID of the Azure ML workspace for compute target attachment                                                                          | `string`                                                                                                                                                      | n/a     |   yes    |
| ml\_workload\_identity                  | AzureML workload managed identity object containing id and principal\_id.                                                                    | ```object({ id = string principal_id = string })```                                                                                                           | n/a     |   yes    |
| ml\_workload\_subjects                  | Custom Kubernetes service account subjects for AzureML workload federation.                                                                  | `list(string)`                                                                                                                                                | n/a     |   yes    |
| resource\_group\_name                   | Name of the resource group containing the workload identity.                                                                                 | `string`                                                                                                                                                      | n/a     |   yes    |
| resource\_prefix                        | Prefix for all resources                                                                                                                     | `string`                                                                                                                                                      | n/a     |   yes    |
| should\_install\_dcgm\_exporter         | Whether to install DCGM exporter for GPU metrics collection                                                                                  | `bool`                                                                                                                                                        | n/a     |   yes    |
| should\_install\_nvidia\_device\_plugin | Whether to install NVIDIA Device Plugin for GPU hardware support                                                                             | `bool`                                                                                                                                                        | n/a     |   yes    |
| should\_install\_prom\_op               | Whether to install Prometheus operator for monitoring                                                                                        | `bool`                                                                                                                                                        | n/a     |   yes    |
| should\_install\_volcano                | Whether to install Volcano scheduler for job scheduling                                                                                      | `bool`                                                                                                                                                        | n/a     |   yes    |
| ssl\_cert\_pem                          | PEM-encoded TLS certificate chain                                                                                                            | `string`                                                                                                                                                      | n/a     |   yes    |
| ssl\_cname                              | CNAME used for HTTPS endpoint                                                                                                                | `string`                                                                                                                                                      | n/a     |   yes    |
| ssl\_key\_pem                           | PEM-encoded private key                                                                                                                      | `string`                                                                                                                                                      | n/a     |   yes    |
| system\_tolerations                     | List of tolerations for AzureML extension system components to schedule on tainted nodes.                                                    | ```list(object({ key = optional(string) operator = string value = optional(string) effect = optional(string) }))```                                           | n/a     |   yes    |
| vc\_name                                | Virtual Cluster (VC) name for advanced Kubernetes compute configuration.                                                                     | `string`                                                                                                                                                      | n/a     |   yes    |
| workload\_tolerations                   | List of tolerations for AzureML workloads (training and inference jobs) to schedule on tainted nodes.                                        | ```list(object({ key = optional(string) operator = string value = optional(string) effect = optional(string) }))```                                           | n/a     |   yes    |
| workspace\_identity\_id                 | Resource ID of user-assigned managed identity for the compute target. If null, SystemAssigned identity will be used.                         | `string`                                                                                                                                                      | n/a     |   yes    |
| workspace\_identity\_principal\_id      | Principal ID of the workspace managed identity for role assignments                                                                          | `string`                                                                                                                                                      | n/a     |   yes    |

## Outputs

| Name                  | Description                                                                 |
|-----------------------|-----------------------------------------------------------------------------|
| azureml\_extension    | The Azure ML extension resource                                             |
| compute\_target\_id   | The ID of the Kubernetes compute target.                                    |
| compute\_target\_name | The name of the Kubernetes compute target.                                  |
| kubernetes\_compute   | The Kubernetes compute target for Azure ML workspace.                       |
| role\_assignments     | Map of role assignments (may be empty when workspace identity not provided) |
<!-- END_TF_DOCS -->
