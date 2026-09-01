<!-- BEGIN_TF_DOCS -->
# Terraform IaC

## Requirements

| Name      | Version          |
|-----------|------------------|
| terraform | >= 1.12.0, < 2.0 |
| azapi     | >= 2.3.0         |

## Providers

| Name  | Version  |
|-------|----------|
| azapi | >= 2.3.0 |

## Resources

| Name                                                                                                                    | Type     |
|-------------------------------------------------------------------------------------------------------------------------|----------|
| [azapi_resource.deployment_clients](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.main](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource)               | resource |
| [azapi_resource.profile](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource)            | resource |
| [azapi_resource.subscription](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource)       | resource |

## Inputs

| Name                           | Description                                                                          | Type           | Default | Required |
|--------------------------------|--------------------------------------------------------------------------------------|----------------|---------|:--------:|
| allowed\_ip\_address\_prefixes | IPv4 or IPv6 CIDR prefixes allowed to access resources associated with the perimeter | `list(string)` | n/a     |   yes    |
| environment                    | Environment for all resources in this module: dev, test, or prod                     | `string`       | n/a     |   yes    |
| instance                       | Instance identifier for naming resources: 001, 002, etc                              | `string`       | n/a     |   yes    |
| location                       | Azure region where all resources will be deployed                                    | `string`       | n/a     |   yes    |
| resource\_group\_id            | Resource ID of the resource group where the perimeter is deployed                    | `string`       | n/a     |   yes    |
| resource\_prefix               | Prefix for all resources in this module                                              | `string`       | n/a     |   yes    |
| subscription\_id               | Subscription ID allowed to access resources associated with the perimeter            | `string`       | n/a     |   yes    |

## Outputs

| Name                 | Description                                                                |
|----------------------|----------------------------------------------------------------------------|
| id                   | Resource ID of the Network Security Perimeter                              |
| profile\_id          | Resource ID of the Network Security Perimeter profile                      |
| propagation\_trigger | Value that changes when the Network Security Perimeter access rules change |
<!-- END_TF_DOCS -->
