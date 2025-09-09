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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| resource\_group | The resource group to deploy the VM host in. | ```object({ name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| subnet\_id | The ID of the subnet to deploy the VM host in | `string` | n/a | yes |
| arc\_onboarding\_identity | The identity for Arc onboarding. | ```object({ id = string })``` | `null` | no |
| host\_machine\_count | The number of host VMs to create if a multi-node cluster is needed | `number` | `1` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| vm\_sku\_size | Size of the VM | `string` | `"Standard_D8s_v3"` | no |
| vm\_username | Username for the VM admin account | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| linux\_virtual\_machine\_name | The names of all Linux virtual machines. |
| private\_ips | The private IP addresses of all VMs. |
| public\_fqdns | The public FQDNs of all VMs. |
| public\_ips | The public IP addresses of all VMs. |
| public\_ssh | SSH command to connect to the first VM. |
| public\_ssh\_permissions | File permissions for the SSH private key. |
| ssh\_private\_key\_path | The path to the SSH private key file. |
| ssh\_public\_key | The SSH public key for all VMs. |
| username | The username for all VMs. |
| virtual\_machines | The created virtual machines. |
| vm\_id | The IDs of all VMs. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
