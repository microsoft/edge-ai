<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# VM Host

Deploys one or more Linux VMs for Arc-connected K3s cluster

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm | >= 4.8.0 |
| local | >= 2.5.0 |
| msgraph | >= 0.2.0 |
| random | >= 3.6.0 |
| tls | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.8.0 |
| local | >= 2.5.0 |
| msgraph | >= 0.2.0 |
| random | >= 3.6.0 |
| tls | >= 4.0.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_role_assignment.vm_admin_login](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.vm_user_login](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_virtual_machine_extension.aad_ssh_login](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [local_sensitive_file.private_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [msgraph_resource_action.current_user](https://registry.terraform.io/providers/microsoft/msgraph/latest/docs/resources/resource_action) | resource |
| [random_password.vm_admin](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
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
| resource\_group | Resource group object containing name and id where resources will be deployed | ```object({ id = string name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| subnet\_id | The ID of the subnet to deploy the VM host in | `string` | n/a | yes |
| arc\_onboarding\_identity | The Principal ID for the identity that will be used for onboarding the cluster to Arc | ```object({ id = string })``` | `null` | no |
| host\_machine\_count | The number of host VMs to create if a multi-node cluster is needed | `number` | `1` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| should\_assign\_current\_user\_vm\_admin | Whether to assign the current Azure AD user the Virtual Machine Administrator Login role (sudo access). Requires Microsoft Graph provider permissions | `bool` | `true` | no |
| should\_create\_public\_ip | Create public IP address for VM. Set to false for private VNet scenarios using Azure Bastion or VPN connectivity. | `bool` | `true` | no |
| should\_create\_ssh\_key | Generate SSH key pair for VM fallback access. Defaults to true to ensure emergency access when Azure AD authentication is unavailable. | `bool` | `true` | no |
| should\_use\_password\_auth | Use password authentication for VM access. When enabled, a random secure password will be generated and stored in Terraform state. | `bool` | `false` | no |
| vm\_admin\_principals | Map of Azure AD principals for Virtual Machine Administrator Login role (sudo access). Keys are descriptive identifiers (e.g., `user@company.com`), values are principal object IDs. | `map(string)` | `{}` | no |
| vm\_eviction\_policy | Eviction policy for Spot VMs: Deallocate (VM stopped, disk retained, can restart) or Delete (VM and disks removed, no storage charges). Only used when vm\_priority is Spot | `string` | `"Delete"` | no |
| vm\_max\_bid\_price | Maximum price per hour in USD for Spot VM. Set to -1 (default) for no price-based eviction - VM will not be evicted for price reasons. Custom values support up to 5 decimal places (e.g., 0.98765). Only used when vm\_priority is Spot | `number` | `-1` | no |
| vm\_priority | VM priority: Regular (production, guaranteed capacity) or Spot (cost-optimized, can be evicted with 30s notice). Spot VMs offer up to 90% cost savings | `string` | `"Regular"` | no |
| vm\_sku\_size | Size of the VM | `string` | `"Standard_D8s_v3"` | no |
| vm\_user\_principals | Map of Azure AD principals for Virtual Machine User Login role (standard access). Keys are descriptive identifiers (e.g., `user@company.com`), values are principal object IDs. | `map(string)` | `{}` | no |
| vm\_username | Username for the VM admin account | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| linux\_virtual\_machine\_name | The names of all Linux virtual machines. |
| private\_ips | The private IP addresses of all VMs. |
| public\_fqdns | The public FQDNs of all VMs. |
| public\_ips | The public IP addresses of all VMs. |
| public\_ssh\_permissions | File permissions for the SSH private key. Only available when SSH key generation enabled. |
| ssh\_private\_key\_path | The path to the SSH private key file. Only available when SSH key generation enabled. |
| ssh\_public\_key | The SSH public key for all VMs. Only available when SSH key generation enabled. |
| username | The username for all VMs. |
| virtual\_machines | The created virtual machines. |
| vm\_admin\_passwords | The generated admin passwords for all VMs. Only available when password authentication is enabled. |
| vm\_connection\_instructions | Connection instructions for VMs with Azure AD authentication and optional fallback methods. |
| vm\_id | The IDs of all VMs. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
