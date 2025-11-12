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
| azapi | n/a |
| azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_arc_kubernetes_cluster_extension.container_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) | resource |
| [azurerm_arc_kubernetes_cluster_extension.platform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) | resource |
| [azurerm_arc_kubernetes_cluster_extension.secret_store](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) | resource |
| [azurerm_federated_identity_credential.federated_identity_cred_aio_instance](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential) | resource |
| [azurerm_federated_identity_credential.federated_identity_cred_sse_aio](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential) | resource |
| [azapi_resource.cluster_oidc_issuer](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_namespace | Azure IoT Operations namespace | `string` | n/a | yes |
| aio\_platform\_config | Install cert-manager and trust-manager extensions | ```object({ install_cert_manager = bool install_trust_manager = bool })``` | n/a | yes |
| aio\_user\_managed\_identity\_id | ID of the User Assigned Managed Identity for the Azure IoT Operations instance | `string` | n/a | yes |
| arc\_connected\_cluster\_id | The resource ID of the connected cluster to deploy Azure IoT Operations Platform to | `string` | n/a | yes |
| connected\_cluster\_name | The name of the connected cluster to deploy Azure IoT Operations to | `string` | n/a | yes |
| edge\_storage\_accelerator | n/a | ```object({ version = string train = string diskStorageClass = string faultToleranceEnabled = bool diskMountPoint = string })``` | n/a | yes |
| enable\_instance\_secret\_sync | Whether to enable secret sync on the Azure IoT Operations instance | `bool` | n/a | yes |
| platform | n/a | ```object({ version = string train = string })``` | n/a | yes |
| resource\_group | Resource group object containing name and id where resources will be deployed | ```object({ id = string name = string })``` | n/a | yes |
| secret\_sync\_controller | n/a | ```object({ version = string train = string })``` | n/a | yes |
| secret\_sync\_identity | Secret Sync Extension user managed identity id and client id | ```object({ id = string client_id = string })``` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| platform\_cluster\_extension\_id | n/a |
| secret\_store\_extension\_cluster\_id | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
