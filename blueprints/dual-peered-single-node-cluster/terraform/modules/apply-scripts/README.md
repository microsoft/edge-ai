<!-- BEGIN_TF_DOCS -->
# Apply Scripts

Sets up an `az connectedk8s proxy`, if needed,  and then runs the corresponding
scripts passed into this module.

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name      | Version |
|-----------|---------|
| azurerm   | n/a     |
| terraform | n/a     |

## Resources

| Name                                                                                                                              | Type        |
|-----------------------------------------------------------------------------------------------------------------------------------|-------------|
| [terraform_data.apply_scripts_enterprise](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource    |
| [terraform_data.apply_scripts_site](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)       | resource    |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription)   | data source |

## Inputs

| Name                                           | Description                                                                                                             | Type                                 | Default                 | Required |
|------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------|--------------------------------------|-------------------------|:--------:|
| aio\_namespace                                 | Azure IoT Operations namespace                                                                                          | `string`                             | n/a                     |   yes    |
| arc\_connected\_cluster\_a                     | n/a                                                                                                                     | ```object({ name = string })```      | n/a                     |   yes    |
| arc\_connected\_cluster\_b                     | n/a                                                                                                                     | ```object({ name = string })```      | n/a                     |   yes    |
| cluster\_a\_key\_vault                         | The Key Vault for Cluster A.                                                                                            | ```object({ name = string })```      | n/a                     |   yes    |
| cluster\_a\_resource\_group                    | The resource group for Cluster A.                                                                                       | ```object({ name = string })```      | n/a                     |   yes    |
| cluster\_a\_secret\_sync\_identity             | The secret sync identity for Cluster A.                                                                                 | ```object({ client_id = string })``` | n/a                     |   yes    |
| cluster\_b\_key\_vault                         | The Key Vault for Cluster B.                                                                                            | ```object({ name = string })```      | n/a                     |   yes    |
| cluster\_b\_resource\_group                    | The resource group for Cluster B.                                                                                       | ```object({ name = string })```      | n/a                     |   yes    |
| cluster\_b\_secret\_sync\_identity             | The secret sync identity for Cluster B.                                                                                 | ```object({ client_id = string })``` | n/a                     |   yes    |
| enterprise\_client\_ca\_configmap\_name        | The name of the Kubernetes configmap containing the client CA certificate                                               | `string`                             | n/a                     |   yes    |
| site\_tls\_ca\_configmap\_name                 | The name of the Kubernetes configmap containing the TLS CA certificate                                                  | `string`                             | n/a                     |   yes    |
| enterprise\_synced\_certificates\_secret\_name | The name of the Kubernetes secret containing certificates synced from Key Vault for the enterprise cluster (Cluster A). | `string`                             | `"certificates-sync-a"` |    no    |
| site\_synced\_certificates\_secret\_name       | The name of the Kubernetes secret containing certificates synced from Key Vault for the site cluster (Cluster B).       | `string`                             | `"certificates-sync-b"` |    no    |
<!-- END_TF_DOCS -->
