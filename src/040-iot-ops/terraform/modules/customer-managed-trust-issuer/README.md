<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure IoT Operations Customer Managed trust

Deploys resources necessary to enable Azure IoT Operations (AIO) with Customer Managed trust.

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
| [azurerm_federated_identity_credential.federated_identity_cred_sse_cert_manager](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential) | resource |
| [azurerm_key_vault_secret.aio_ca_cert_chain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.aio_ca_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.aio_root_ca_cert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azapi_resource.cluster_oidc_issuer](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_ca | CA certificate for the MQTT broker, can be either Root CA or Root CA with any number of Intermediate CAs. If not provided, a self-signed Root CA with a intermediate will be generated. Only valid when Trust Source is set to CustomerManaged | ```object({ root_ca_cert_pem = string ca_cert_chain_pem = string ca_key_pem = string })``` | n/a | yes |
| connected\_cluster\_name | The name of the connected cluster to deploy Azure IoT Operations to | `string` | n/a | yes |
| customer\_managed\_trust\_settings | Values for AIO CustomerManaged trust resources | ```object({ issuer_name = string issuer_kind = string configmap_name = string configmap_key = string })``` | n/a | yes |
| key\_vault | The name and id of the existing key vault for Azure IoT Operations instance | ```object({ name = string id = string })``` | n/a | yes |
| resource\_group | Name and ID of the pre-existing resource group in which to create resources | ```object({ id = string name = string })``` | n/a | yes |
| sse\_user\_managed\_identity | Secret Sync Extension user managed identity id and client id | ```object({ id = string client_id = string })``` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| scripts | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
