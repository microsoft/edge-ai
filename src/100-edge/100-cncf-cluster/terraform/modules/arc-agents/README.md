<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Arc Agents Deployment

This module uses the Helm provider to deploy Azure Arc agents to a Kubernetes cluster
if you are not using Azure CLI provided by the ubuntu-k3s module.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azurerm | >= 4.8.0 |
| helm | >= 2.17.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.8.0 |
| helm | >= 2.17.0 |
| http | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.arc_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |
| [http_http.helm_config](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster\_name | Name of the created ARC K8s cluster | `string` | n/a | yes |
| custom\_locations\_oid | The object id of the Custom Locations Entra ID application for your tenant. If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions. ```sh az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv``` | `string` | n/a | yes |
| http\_proxy | HTTP proxy URL | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| private\_key\_pem | Private key for onboarding | `string` | n/a | yes |
| resource\_group | Resource group object containing name and id where resources will be deployed | ```object({ name = string id = optional(string) })``` | n/a | yes |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
