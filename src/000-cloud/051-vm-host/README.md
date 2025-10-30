---
title: Virtual Machine Host
description: Component for onboarding a new Azure VM for the purposes of installing and testing out an edge deployment including Azure VNet and Azure VM
author: Edge AI Team
ms.date: 06/07/2025
ms.topic: reference
keywords:
  - virtual machine host
  - azure vm
  - azure vnet
  - edge deployment
  - terraform
  - bicep
  - ssh access
  - jit access
estimated_reading_time: 2
---

## Virtual Machine Host

Component for deploying Azure VMs with Azure AD (Microsoft Entra ID) RBAC-based SSH authentication
for secure, centralized access control. Ideal for edge deployments, development environments, and
jump box scenarios.

This includes the following:

* Azure VNet integration
* Azure VM with system-assigned managed identity
* Azure AD SSH authentication (AADSSHLoginForLinux extension)
* Optional SSH key fallback for emergency access
* Optional public IP (supports private VNet scenarios)
* Optional RBAC role assignments for Azure AD principals

## Azure AD RBAC Authentication

This component deploys VMs with Azure AD (Microsoft Entra ID) RBAC-based SSH authentication as the
primary access method, eliminating SSH key distribution and enabling centralized access control.

**Key Features**:

* Ephemeral SSH certificates issued by Azure AD
* MFA support via Conditional Access policies
* Centralized RBAC through Azure role assignments
* Automatic access revocation when users removed from roles
* Audit trails via Azure Activity Log
* SSH keys optional for emergency fallback only

**Required Setup** (one-time):

```bash
az extension add --name ssh
```

## Connection Methods

| Method                | Authentication       | Use Case                    | Requirements                        |
|-----------------------|----------------------|-----------------------------|-------------------------------------|
| Azure AD (Public IP)  | Azure AD certificate | Standard VM access          | Public IP, RBAC role                |
| Azure AD (Private IP) | Azure AD certificate | Private VNet access         | VPN/ExpressRoute/Peering, RBAC role |
| Azure Bastion         | Azure AD certificate | Recommended for private VMs | Bastion deployed, RBAC role         |
| SSH Key Fallback      | SSH private key      | Emergency only              | `should_create_ssh_key = true`      |

## Connection Examples

### Public VM with Azure AD

```bash
az login

az ssh vm -n vm-myprefix-aio-dev-001-0 -g rg-myprefix-dev-001
```

### Private VM with VPN or ExpressRoute

```bash
az login

az ssh vm --ip 10.0.1.4
```

### Private VM with Azure Bastion (Recommended)

```bash
az login

az network bastion ssh \
  --name bastion-myprefix-dev \
  --resource-group rg-myprefix-dev-001 \
  --target-resource-id /subscriptions/.../virtualMachines/vm-myprefix-aio-dev-001-0 \
  --auth-type AAD
```

### Emergency SSH Key Fallback

```bash
ssh -i .ssh/vm-myprefix-aio-dev-001-id_rsa azureuser@vm-hostname.eastus.cloudapp.azure.com
```

### Emergency Password Fallback

```bash
# Retrieve password from Terraform output
terraform output -raw vm_admin_passwords

# Connect using password
ssh azureuser@vm-hostname.eastus.cloudapp.azure.com
# Enter password when prompted
```

## Authentication Methods

This component supports three authentication layers:

1. **Azure AD (Primary)** - RBAC-based authentication via Azure AD principals (recommended)
2. **SSH Keys (Default Fallback)** - Auto-generated SSH key pair for emergency access
3. **Password (Optional)** - Auto-generated secure password stored in Terraform state

### Authentication Configuration

**SSH Keys** (Default):

* More secure than passwords
* Recommended by security best practices
* Key file stored locally in `.ssh/` directory
* Set `should_create_ssh_key = true` (default)

**Password Authentication** (Optional):

* Simpler for environments without SSH key management
* Password auto-generated (20 characters)
* Stored in Terraform state (sensitive)
* Set `should_use_password_auth = true`

**Both methods can be enabled simultaneously** for maximum flexibility and redundancy.

## RBAC Roles

Assign one of these roles to Azure AD principals for VM access:

| Role                                | Access Level  | Permissions                        |
|-------------------------------------|---------------|------------------------------------|
| Virtual Machine Administrator Login | Admin (sudo)  | Full sudo access, all commands     |
| Virtual Machine User Login          | Standard user | Standard user permissions, no sudo |

**Assignment Methods**:

1. **Automatic** (via Terraform): Provide `vm_admin_principals` or `vm_user_principals` list
2. **Manual** (via Azure Portal): Navigate to VM → Access Control (IAM) → Add role assignment
3. **Manual** (via Azure CLI):

```bash
az role assignment create \
  --assignee user@example.com \
  --role "Virtual Machine Administrator Login" \
  --scope /subscriptions/.../resourceGroups/rg-name
```

## Network Requirements

**VM Outbound Connectivity** (HTTPS/443):

* `https://packages.microsoft.com` - VM extension packages
* `https://login.microsoftonline.com` - Azure AD authentication
* `https://pas.windows.net` - Azure RBAC validation
* `http://169.254.169.254` - Azure Instance Metadata Service (IMDS)

**Inbound**:

* SSH port 22 (controlled by NSG/JIT policies)
* No additional ports required for Azure AD authentication

## Configuration Variables

### Azure AD RBAC (Optional)

| Variable              | Type         | Default | Description                                         |
|-----------------------|--------------|---------|-----------------------------------------------------|
| `vm_admin_principals` | list(string) | `[]`    | Azure AD principal object IDs for admin role (sudo) |
| `vm_user_principals`  | list(string) | `[]`    | Azure AD principal object IDs for user role         |

### Authentication Fallback Options

| Variable                   | Type | Default | Description                                                                                         |
|----------------------------|------|---------|-----------------------------------------------------------------------------------------------------|
| `should_create_ssh_key`    | bool | `true`  | Generate SSH key pair for emergency fallback access                                                 |
| `should_use_password_auth` | bool | `false` | Use password authentication for VM access. Auto-generates 20-character secure password when enabled |

### Network Configuration (Optional)

| Variable                  | Type | Default | Description                                               |
|---------------------------|------|---------|-----------------------------------------------------------|
| `should_create_public_ip` | bool | `true`  | Create public IP. Set to false for private VNet scenarios |

## Troubleshooting

### Access Denied Despite RBAC Role

* Wait 10 minutes for RBAC propagation
* Verify role assignment: `az role assignment list --assignee user@example.com`
* Check correct scope (resource group or VM)

### Connection Closed Immediately

* Verify system-assigned identity enabled on VM
* Verify AADSSHLoginForLinux extension installed and status "Succeeded"
* Check VM outbound connectivity to required endpoints
* Verify NSG allows SSH port 22

### Exit Code 22 (Invalid Argument)

* System-assigned managed identity not enabled on VM
* Solution: Redeploy with updated configuration

### Exit Code 23 (Permission Denied)

* Old AADLoginForLinux extension conflicts with AADSSHLoginForLinux
* Solution: Remove old extension before deploying new one

## Security Considerations

**Azure AD Benefits**:

* ✅ No SSH key storage or distribution
* ✅ MFA enforcement via Conditional Access
* ✅ Automatic access revocation
* ✅ Centralized audit logging
* ✅ Ephemeral certificates (automatic rotation)

**Private VNet Deployment**:

* Set `should_create_public_ip = false` for no public internet exposure
* Use Azure Bastion for browser-based access (no VPN client required)
* Use VPN Gateway or ExpressRoute for private IP access from corporate network

## Terraform

Refer to [Terraform Components - Getting Started](../README.md#terraform-components---getting-started) for
deployment instructions.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
