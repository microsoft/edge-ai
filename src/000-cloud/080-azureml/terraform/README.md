<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Machine Learning Component

Creates Azure Machine Learning workspace with optional compute cluster and
AKS cluster integration for AI model training and deployment. Integrates with
existing cloud infrastructure including Key Vault, Storage Account, Application Insights, and networking.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azurerm | >= 4.8.0 |
| msgraph | >= 0.2.0 |
| tls | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| msgraph | >= 0.2.0 |

## Resources

| Name | Type |
|------|------|
| [msgraph_resource_action.current_user](https://registry.terraform.io/providers/microsoft/msgraph/latest/docs/resources/resource_action) | resource |

## Modules

| Name | Source | Version |
|------|--------|---------|
| compute\_cluster | ./modules/compute-cluster | n/a |
| inference\_cluster\_integration | ./modules/inference-cluster-integration | n/a |
| network | ./modules/network | n/a |
| registry | ./modules/registry | n/a |
| workspace | ./modules/workspace | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| acr | Azure Container Registry object from 060-acr component (optional). | ```object({ id = optional(string) })``` | n/a | yes |
| application\_insights | Application Insights object from 020-observability component. | ```object({ id = string name = string instrumentation_key = string })``` | n/a | yes |
| environment | The environment for the deployment. | `string` | n/a | yes |
| key\_vault | Key Vault object from 010-security-identity component. | ```object({ id = string name = string })``` | n/a | yes |
| location | Azure region for all resources. | `string` | n/a | yes |
| resource\_group | Resource group object from 000-resource-group component. | ```object({ name = string id = optional(string) location = optional(string) })``` | n/a | yes |
| resource\_prefix | Prefix for all resource names. | `string` | n/a | yes |
| storage\_account | Storage Account object from 030-data component. | ```object({ id = string name = string })``` | n/a | yes |
| aks\_cluster\_purpose | Purpose of AKS cluster: DevTest, DenseProd, or FastProd. | `string` | `"DevTest"` | no |
| aks\_compute\_target\_name | Name of the AKS compute target in ML workspace. Otherwise, 'ml{resource\_prefix\_clean}{environment\_clean}{instance}' truncated to 16 characters. | `string` | `null` | no |
| cluster\_integration\_default\_instance\_type | Default instance type for the Kubernetes compute.. | `string` | `"defaultinstancetype"` | no |
| cluster\_integration\_description | Description for the AKS integration compute target. Otherwise, 'Azure ML AKS compute target for {resource\_prefix}-{environment}-{instance}'. | `string` | `null` | no |
| cluster\_integration\_disable\_local\_auth | Whether to disable local authentication for the AKS integration compute target. | `bool` | `true` | no |
| cluster\_integration\_extension\_instance\_release\_train | Extension instance release train for Azure ML extension. | `string` | `"Stable"` | no |
| cluster\_integration\_instance\_types | Instance types configuration for Kubernetes compute. Key is the instance type name, value contains nodeSelector and resource specifications. | ```map(object({ nodeSelector = optional(map(string)) resources = optional(object({ requests = optional(map(string)) limits = optional(map(string)) })) }))``` | `null` | no |
| cluster\_integration\_kubernetes\_namespace | Kubernetes namespace for ML workloads. Otherwise, 'azureml'. | `string` | `"azureml"` | no |
| cluster\_integration\_vc\_name | Virtual Cluster (VC) name for advanced Kubernetes compute configuration. | `string` | `null` | no |
| cluster\_integration\_workspace\_identity\_id | Resource ID of user-assigned managed identity for the compute target. If null, SystemAssigned identity will be used. | `string` | `null` | no |
| compute\_cluster\_idle\_duration | Time to wait before scaling down idle nodes. Format: PT{minutes}M (e.g., PT15M for 30 minutes). | `string` | `"PT30M"` | no |
| compute\_cluster\_max\_nodes | Maximum number of nodes in compute cluster for auto-scaling. Default: 1 (cost-optimized for single-model training). | `number` | `1` | no |
| compute\_cluster\_min\_nodes | Minimum number of nodes in compute cluster for auto-scaling. Default: 0 (cost-optimized, scales to zero when idle). | `number` | `0` | no |
| compute\_cluster\_name | Name of the compute cluster for ML training workloads. Otherwise, 'cluster-{resource\_prefix}-{environment}-{instance}'. | `string` | `null` | no |
| compute\_cluster\_node\_public\_ip\_enabled | Whether the compute cluster nodes will have public IPs. Set to false for private endpoint scenarios to enhance security. | `bool` | `false` | no |
| compute\_cluster\_ssh\_public\_access\_enabled | Whether to enable public SSH port access to compute cluster nodes. Set to false for private endpoint scenarios to prevent unauthorized access. | `bool` | `false` | no |
| compute\_cluster\_subnet | Existing subnet for the Azure ML compute cluster from networking components. | ```object({ id = string name = optional(string) })``` | `null` | no |
| compute\_cluster\_vm\_priority | VM priority for compute cluster nodes: Dedicated (production, higher cost) or LowPriority (development, 60-80% cost savings but can be preempted). | `string` | `"Dedicated"` | no |
| compute\_cluster\_vm\_size | VM size for compute cluster nodes. Standard\_DS3\_v2 (4 vCPUs, 14 GiB RAM) recommended for balanced production ML workloads. | `string` | `"Standard_DS3_v2"` | no |
| default\_outbound\_access\_enabled | Whether to enable default outbound internet access for Azure ML subnets | `bool` | `false` | no |
| extension\_name | Name of the Azure ML extension for AKS cluster. Otherwise, 'azureml-{resource\_prefix}-{environment}-{instance}'. | `string` | `null` | no |
| inference\_router\_service\_type | Service type for inference router: LoadBalancer, NodePort, or ClusterIP. | `string` | `"ClusterIP"` | no |
| instance | Instance identifier for the deployment. | `string` | `"001"` | no |
| kubernetes | The Kubernetes cluster object from 070-kubernetes component. | ```object({ id = string name = string resource_group_name = string default_node_pool = list(object({ name = string node_count = number vm_size = string })) })``` | `null` | no |
| ml\_workload\_identity | AzureML workload managed identity object from security identity containing id and principal\_id. | ```object({ id = string principal_id = string })``` | `null` | no |
| ml\_workload\_subjects | Custom Kubernetes service account subjects for AzureML workload federation. Example: ['system:serviceaccount:azureml:azureml-workload', 'system:serviceaccount:osmo:osmo-workload'] | `list(string)` | `null` | no |
| nat\_gateway | NAT gateway object from the networking component for managed outbound access. | ```object({ id = string name = string })``` | `null` | no |
| network\_security\_group | Network security group from 050-networking component. | ```object({ id = string })``` | `null` | no |
| private\_endpoint\_subnet\_id | The ID of the subnet where the private endpoint will be created | `string` | `null` | no |
| registry\_acr | Azure Container Registry for registry (from cloud ACR component) | ```object({ id = string name = string })``` | `null` | no |
| registry\_description | Description for the AzureML Registry. Otherwise, 'Azure Machine Learning Registry for {resource\_prefix}-{environment}-{instance}' | `string` | `null` | no |
| registry\_should\_enable\_public\_network\_access | Whether to enable public network access to the registry. | `bool` | `false` | no |
| registry\_storage\_account | Storage account for registry (from cloud data component) | ```object({ id = string name = string })``` | `null` | no |
| should\_assign\_current\_user\_workspace\_roles | Whether to assign the current Azure AD user roles for accessing and using the Machine Learning workspace (Contributor on workspace and Storage Blob Data Contributor on storage account). | `bool` | `true` | no |
| should\_assign\_workspace\_managed\_identity\_roles | Whether to assign the workspace system-assigned managed identity roles to access dependent Azure services (Storage, ACR, Key Vault, Application Insights). | `bool` | `true` | no |
| should\_create\_compute\_cluster | Whether to create a compute cluster for ML training workloads. | `bool` | `true` | no |
| should\_create\_compute\_cluster\_snet | Whether to create the subnet for the Azure ML compute cluster. | `bool` | `true` | no |
| should\_deploy\_registry | Whether to deploy AzureML Registry. | `bool` | `false` | no |
| should\_enable\_aks\_inference | Whether to enable inference workloads on the AKS cluster. | `bool` | `true` | no |
| should\_enable\_aks\_training | Whether to enable training workloads on the AKS cluster. | `bool` | `true` | no |
| should\_enable\_inference\_router\_ha | Whether to enable high availability for inference router. | `bool` | `true` | no |
| should\_enable\_private\_endpoint | Whether to create a private endpoint for the Azure ML workspace | `bool` | `false` | no |
| should\_enable\_public\_network\_access | Whether to enable public network access to the workspace. | `bool` | `false` | no |
| should\_install\_dcgm\_exporter | Whether to install DCGM exporter for GPU metrics collection in Azure ML extension. | `bool` | `true` | no |
| should\_install\_nvidia\_device\_plugin | Whether to install NVIDIA Device Plugin for GPU hardware support in Azure ML extension. | `bool` | `false` | no |
| should\_install\_prom\_op | Whether to install Prometheus operator for monitoring in Azure ML extension. Set to false if Azure Monitor is already enabled on AKS. | `bool` | `false` | no |
| should\_install\_volcano | Whether to install Volcano scheduler for job scheduling in Azure ML extension. | `bool` | `true` | no |
| should\_integrate\_aks\_cluster | Whether to integrate an existing AKS cluster as compute target for ML workloads. | `bool` | `false` | no |
| ssl\_cert\_pem | PEM-encoded TLS certificate chain (server first then intermediates) or empty when not using HTTPS. | `string` | `null` | no |
| ssl\_cname | CNAME used for HTTPS endpoint; required when providing cert/key; otherwise empty. | `string` | `null` | no |
| ssl\_key\_pem | PEM-encoded unencrypted private key matching ssl\_cert\_pem or empty when not using HTTPS. | `string` | `null` | no |
| subnet\_address\_prefixes\_azureml | Address prefixes for the Azure ML compute cluster subnet. | `list(string)` | ```[ "10.0.4.0/24" ]``` | no |
| system\_tolerations | Tolerations for AzureML extension system components to schedule on tainted nodes. Default: empty list (no tolerations). | ```list(object({ key = optional(string) operator = optional(string, "Exists") value = optional(string) effect = optional(string) }))``` | `[]` | no |
| virtual\_network | Virtual network from 050-networking component. | ```object({ name = string })``` | `null` | no |
| virtual\_network\_id | The ID of the virtual network to link to the private DNS zone | `string` | `null` | no |
| workload\_tolerations | Tolerations for AzureML workloads (training and inference) to schedule on tainted nodes. Default: empty list (no tolerations). | ```list(object({ key = optional(string) operator = optional(string, "Exists") value = optional(string) effect = optional(string) }))``` | `[]` | no |
| workspace\_friendly\_name | Friendly display name for the workspace. (Default, {var.resource\_prefix}-{var.environment}-{var.instance} ML Workspace) | `string` | `null` | no |
| workspace\_name | Name of the Azure Machine Learning workspace. Otherwise, 'mlw-{resource\_prefix}-{environment}-{instance}'. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| azureml\_extension | The Azure ML extension resource. |
| azureml\_workspace | The Azure Machine Learning workspace object. |
| compute\_cluster | The Azure Machine Learning compute cluster object. |
| compute\_cluster\_id | The ID of the compute cluster. |
| compute\_cluster\_name | The name of the compute cluster. |
| compute\_cluster\_principal\_id | The Principal ID of the compute cluster System Assigned Managed Service Identity. |
| kubernetes\_compute | The Azure ML Kubernetes compute resource. |
| ml\_workload\_identity | The AzureML workload managed identity passed into the component. |
| registry | AzureML Registry information. |
| workspace\_id | The immutable resource ID of the workspace. |
| workspace\_name | The name of the workspace. |
| workspace\_principal\_id | The Principal ID of the workspace System Assigned Managed Service Identity. |
| workspace\_private\_dns\_zones | The private DNS zones for Azure ML workspace. |
| workspace\_private\_endpoint | The private endpoint resource for Azure ML workspace. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
