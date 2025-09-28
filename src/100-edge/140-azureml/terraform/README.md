<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Machine Learning Arc Extension

Installs Azure Machine Learning extension on Arc-enabled Kubernetes cluster
with TLS configuration for secure inference endpoints. Provides edge-specific
ML capabilities including distributed training and model deployment.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azurerm | >= 4.8.0 |
| tls | >= 4.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| inference\_cluster\_integration | ./modules/inference-cluster-integration | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| connected\_cluster | Connected cluster object containing id and name for Arc-enabled Kubernetes cluster | ```object({ id = string name = string })``` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Azure region for all resources. | `string` | n/a | yes |
| machine\_learning\_workspace | Azure Machine Learning workspace object containing id, name, and location for compute target attachment | ```object({ id = string name = string location = string })``` | n/a | yes |
| resource\_group | Resource group object containing name and id where Arc-connected cluster and relay resources reside | ```object({ id = string name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| arc\_cluster\_purpose | Purpose of Arc cluster: DevTest, DenseProd, or FastProd | `string` | `"DevTest"` | no |
| arc\_compute\_target\_name | Name of Arc compute target in ML workspace. Otherwise, 'arc-compute-{resource\_prefix}-{environment}-{instance}' | `string` | `null` | no |
| cluster\_integration\_default\_instance\_type | Default instance type for the Kubernetes compute.. | `string` | `"defaultinstancetype"` | no |
| cluster\_integration\_description | Description for the Arc integration compute target. Otherwise, 'Azure ML Arc compute target for {resource\_prefix}-{environment}-{instance}'. | `string` | `null` | no |
| cluster\_integration\_disable\_local\_auth | Whether to disable local authentication for the Arc integration compute target. | `bool` | `true` | no |
| cluster\_integration\_extension\_instance\_release\_train | Extension instance release train for Azure ML extension. | `string` | `"Stable"` | no |
| cluster\_integration\_instance\_types | Instance types configuration for Kubernetes compute. Key is the instance type name, value contains nodeSelector and resource specifications. | ```map(object({ nodeSelector = optional(map(string)) resources = optional(object({ requests = optional(map(string)) limits = optional(map(string)) })) }))``` | `null` | no |
| cluster\_integration\_kubernetes\_namespace | Kubernetes namespace for ML workloads. Otherwise, 'azureml'. | `string` | `"azureml"` | no |
| cluster\_integration\_vc\_name | Virtual Cluster (VC) name for advanced Kubernetes compute configuration. | `string` | `null` | no |
| cluster\_integration\_workspace\_identity\_id | Resource ID of user-assigned managed identity for the compute target. If null, SystemAssigned identity will be used. | `string` | `null` | no |
| extension\_name | Name of the Azure ML extension. Otherwise, 'azureml-{resource\_prefix}-{environment}-{instance}' | `string` | `null` | no |
| inference\_router\_service\_type | Service type for inference router: LoadBalancer, NodePort, or ClusterIP | `string` | `"ClusterIP"` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| ml\_workload\_identity | AzureML workload managed identity object containing id and principal\_id. | ```object({ id = string principal_id = string })``` | `null` | no |
| ml\_workload\_subjects | Custom Kubernetes service account subjects for AzureML workload federation. Example: ['system:serviceaccount:azureml:azureml-workload', 'system:serviceaccount:osmo:osmo-workload'] | `list(string)` | `null` | no |
| should\_enable\_inference | Whether to enable inference workloads on the Arc-enabled cluster | `bool` | `true` | no |
| should\_enable\_inference\_router\_ha | Whether to enable high availability for inference router | `bool` | `true` | no |
| should\_enable\_training | Whether to enable training workloads on the Arc-enabled cluster | `bool` | `true` | no |
| should\_install\_dcgm\_exporter | Whether to install DCGM exporter for GPU metrics collection | `bool` | `false` | no |
| should\_install\_nvidia\_device\_plugin | Whether to install NVIDIA Device Plugin for GPU hardware support | `bool` | `false` | no |
| should\_install\_prom\_op | Whether to install Prometheus operator for monitoring | `bool` | `false` | no |
| should\_install\_volcano | Whether to install Volcano scheduler for job scheduling | `bool` | `false` | no |
| ssl\_cert\_pem | PEM-encoded TLS certificate chain (server first then intermediates) or empty when not using HTTPS | `string` | `null` | no |
| ssl\_cname | CNAME used for HTTPS endpoint; required when providing cert/key; otherwise empty | `string` | `null` | no |
| ssl\_key\_pem | PEM-encoded unencrypted private key matching ssl\_cert\_pem or empty when not using HTTPS | `string` | `null` | no |
| system\_tolerations | Tolerations for AzureML extension system components to schedule on tainted nodes. Default: empty list (no tolerations). | ```list(object({ key = optional(string) operator = optional(string, "Exists") value = optional(string) effect = optional(string) }))``` | `[]` | no |
| workload\_tolerations | Tolerations for AzureML workloads (training and inference) to schedule on tainted nodes. Default: empty list (no tolerations). | ```list(object({ key = optional(string) operator = optional(string, "Exists") value = optional(string) effect = optional(string) }))``` | `[]` | no |
| workspace\_identity\_principal\_id | Principal ID of workspace managed identity for role assignments. Otherwise, roles not assigned. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| extension | The Azure ML extension resource for Arc-enabled cluster integration |
| kubernetes\_compute | Arc Kubernetes compute target (null when not created) |
| role\_assignments | Map of role assignments for Arc cluster (may be empty) |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
