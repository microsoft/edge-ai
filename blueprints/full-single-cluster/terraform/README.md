<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Terraform IaC

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.2.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.8.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| cncf\_cluster\_install | ../../../src/020-cncf-cluster/terraform | n/a |
| iot\_ops\_cloud\_requirements | ../../../src/030-iot-ops-cloud-reqs/terraform | n/a |
| iot\_ops\_install | ../../../src/040-iot-ops/terraform | n/a |
| iot\_ops\_utilities | ../../../src/080-iot-ops-utility/terraform | n/a |
| messaging | ../../../src/050-messaging/terraform | n/a |
| observability | ../../../src/070-observability/terraform | n/a |
| onboard\_requirements | ../../../src/005-onboard-reqs/terraform | n/a |
| storage | ../../../src/060-cloud-data-persistence/terraform | n/a |
| vm\_host | ../../../src/010-vm-host/terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
