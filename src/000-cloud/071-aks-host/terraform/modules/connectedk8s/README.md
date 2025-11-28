<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Arc Cluster Instance Module

Deploys Azure Arc cluster instances

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| tls | >= 4.0.5 |

## Providers

| Name | Version |
|------|---------|
| azapi | >= 2.3.0 |
| external | n/a |
| tls | >= 4.0.5 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.arc](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [tls_private_key.arc_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [external_external.public_key](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| resource\_group | Resource group object containing name and id where resources will be deployed | ```object({ name = string id = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| connected\_cluster\_id | n/a |
| connected\_cluster\_name | n/a |
| oidc\_issuer\_url | n/a |
| private\_key\_pem | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
