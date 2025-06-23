<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Terraform IaC

## Providers

| Name | Version |
|------|---------|
| azurerm | n/a |
| helm | n/a |
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
| custom\_locations\_oid | Object ID of the custom location. Get by executing az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv | `string` | n/a | yes |
| http\_proxy | HTTP proxy URL | `string` | n/a | yes |
| location | Location for all resources in this module. | `string` | n/a | yes |
| private\_key\_pem | Private key for onboarding | `string` | n/a | yes |
| resource\_group | n/a | ```object({ name = string id = optional(string) })``` | n/a | yes |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
