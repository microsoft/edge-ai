<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure IoT Instance post-installation enablement

Enables secret-sync on the Azure IoT instance after the instance is created.

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
| [azapi_resource.default_aio_keyvault_secret_provider_class](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azurerm_federated_identity_credential.federated_identity_cred_aio_instance](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential) | resource |
| [azurerm_federated_identity_credential.federated_identity_cred_sse_aio](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential) | resource |
| [azapi_resource.cluster_oidc_issuer](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_namespace | Azure IoT Operations namespace | `string` | n/a | yes |
| aio\_user\_managed\_identity\_id | ID of the User Assigned Managed Identity for the Azure IoT Operations instance | `string` | n/a | yes |
| connected\_cluster\_location | The location of the connected cluster resource | `string` | n/a | yes |
| connected\_cluster\_name | The name of the connected cluster to deploy Azure IoT Operations to | `string` | n/a | yes |
| custom\_location\_id | The resource ID of the Custom Location. | `string` | n/a | yes |
| enable\_instance\_secret\_sync | Whether to enable secret sync on the Azure IoT Operations instance | `bool` | n/a | yes |
| key\_vault | The name and id of the existing key vault for Azure IoT Operations instance | ```object({ name = string id = string })``` | n/a | yes |
| resource\_group | Name and ID of the pre-existing resource group in which to create resources | ```object({ id = string name = string })``` | n/a | yes |
| sse\_user\_managed\_identity | Secret Sync Extension user managed identity id and client id | ```object({ id = string client_id = string })``` | n/a | yes |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
