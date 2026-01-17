<!-- BEGIN_TF_DOCS -->
# Virtual Machine Module

Deploys a Linux VM with Azure AD RBAC authentication and optional Arc connectivity.
SSH keys are optional for emergency fallback; Azure AD authentication is primary.

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm   | >= 4.51.0       |

## Providers

| Name    | Version   |
|---------|-----------|
| azurerm | >= 4.51.0 |

## Resources

| Name                                                                                                                                            | Type     |
|-------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| [azurerm_linux_virtual_machine.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface)         | resource |
| [azurerm_public_ip.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip)                         | resource |

## Inputs

| Name                          | Description                                                                                               | Type     | Default | Required |
|-------------------------------|-----------------------------------------------------------------------------------------------------------|----------|---------|:--------:|
| admin\_password               | Admin password for VM authentication. Can be null for SSH key-only authentication.                        | `string` | n/a     |   yes    |
| label\_prefix                 | Prefix to be used for all resource names                                                                  | `string` | n/a     |   yes    |
| location                      | Azure region where all resources will be deployed                                                         | `string` | n/a     |   yes    |
| resource\_group\_name         | Name of the resource group                                                                                | `string` | n/a     |   yes    |
| should\_create\_public\_ip    | Whether to create a public IP address for the VM                                                          | `bool`   | n/a     |   yes    |
| subnet\_id                    | ID of the subnet to deploy the VM in                                                                      | `string` | n/a     |   yes    |
| vm\_eviction\_policy          | Eviction policy for Spot VMs: Deallocate or Delete                                                        | `string` | n/a     |   yes    |
| vm\_index                     | Index of the VM for deployment of multiple VMs                                                            | `number` | n/a     |   yes    |
| vm\_max\_bid\_price           | Maximum price per hour in USD for Spot VM. -1 for no price-based eviction                                 | `number` | n/a     |   yes    |
| vm\_priority                  | VM priority: Regular or Spot                                                                              | `string` | n/a     |   yes    |
| vm\_sku\_size                 | Size of the VM                                                                                            | `string` | n/a     |   yes    |
| vm\_username                  | Username for the VM admin account                                                                         | `string` | n/a     |   yes    |
| arc\_onboarding\_identity\_id | ID of the User Assigned Managed Identity for Arc onboarding. Can be null for VMs without Arc connectivity | `string` | `null`  |    no    |
| ssh\_public\_key              | SSH public key for VM authentication. Can be null for Azure AD-only authentication                        | `string` | `null`  |    no    |

## Outputs

| Name                          | Description                      |
|-------------------------------|----------------------------------|
| linux\_virtual\_machine\_name | The name of the VM               |
| private\_ip                   | The private IP address of the VM |
| public\_fqdn                  | The public FQDN of the VM        |
| public\_ip                    | The public IP address of the VM  |
| virtual\_machine              | The complete VM resource         |
| vm\_id                        | The ID of the VM                 |
<!-- END_TF_DOCS -->
