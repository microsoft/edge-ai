<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Partial Single Node Cluster Blueprint

This blueprint is designed to deploy a single-node, Arc-enabled Kubernetes cluster without Azure IoT Operations.
It focuses solely on the edge CNCF cluster component without any other edge components
such as IoT Ops, Observability, or Messaging.

This blueprint will:

1. Deploy required cloud components (Resource Group, Security/Identity, VM Host)
2. Deploy the CNCF cluster using scripts from Key Vault
3. Ensure proper role assignments for Key Vault access

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.8.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| cloud\_resource\_group | ../../../src/000-cloud/000-resource-group/terraform | n/a |
| cloud\_security\_identity | ../../../src/000-cloud/010-security-identity/terraform | n/a |
| cloud\_vm\_host | ../../../src/000-cloud/050-vm-host/terraform | n/a |
| edge\_cncf\_cluster | ../../../src/100-edge/100-cncf-cluster/terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Azure region where resources will be deployed | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| custom\_locations\_oid | The object id of the Custom Locations Entra ID application for your tenant. If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions. ```sh az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv``` | `string` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| should\_get\_custom\_locations\_oid | Whether to get Custom Locations Object ID using Terraform's azuread provider. (Otherwise, provided by 'custom\_locations\_oid' or `az connectedk8s enable-features` for custom-locations on cluster setup if not provided.) | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| arc\_connected\_cluster | The Arc resource for the connected cluster. |
| arc\_onboarding\_identity | The identity used for Arc onboarding. |
| azure\_arc\_proxy\_command | The AZ CLI command to Arc Connect Proxy to the cluster. |
| key\_vault | The Key Vault resource. |
| public\_ssh | The SSH command to access the VM. |
| resource\_group | The Azure Resource Group containing all resources. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
