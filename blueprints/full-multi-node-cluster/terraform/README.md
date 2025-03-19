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
| vm\_host | ../../../src/010-vm-host/terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| custom\_locations\_oid | The object id of the Custom Locations Entra ID application for your tenant. If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions. ```sh az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv``` | `string` | `null` | no |
| host\_machine\_count | The number of host machines for the cluster. (The first host machine will be the cluster server) | `number` | `3` | no |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| should\_get\_custom\_locations\_oid | Whether to get Custom Locations Object ID using Terraform's azuread provider. (Otherwise, provided by 'custom\_locations\_oid' or `az connectedk8s enable-features` for custom-locations on cluster setup if not provided.) | `bool` | `true` | no |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
