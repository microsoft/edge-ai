<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# VM Host

Deploys one or more Linux VMs for Arc-connected K3s cluster

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| local | n/a |
| tls | n/a |

## Resources

| Name | Type |
|------|------|
| [local_sensitive_file.private_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [tls_private_key.ssh](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |

## Modules

| Name | Source | Version |
|------|--------|---------|
| virtual\_machine | ./modules/virtual-machine | n/a |
| virtual\_network | ./modules/virtual-network | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_group | n/a | ```object({ name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| arc\_onboarding\_identity | n/a | ```object({ id = string })``` | `null` | no |
| host\_machine\_count | The number of host VMs to create if a multi-node cluster is needed. | `number` | `1` | no |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| vm\_sku\_size | Size of the VM | `string` | `"Standard_D8s_v3"` | no |
| vm\_username | Username used for the host VM that will be given kube-config settings on setup. (Otherwise, 'resource\_prefix' if it exists as a user) | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| linux\_virtual\_machine\_name | n/a |
| private\_ips | n/a |
| public\_fqdns | n/a |
| public\_ips | n/a |
| public\_ssh | n/a |
| public\_ssh\_permissions | n/a |
| ssh\_private\_key\_path | The path to the SSH private key file |
| ssh\_public\_key | The SSH public key for all VMs |
| username | n/a |
| virtual\_machines | n/a |
| vm\_id | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
