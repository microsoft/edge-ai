# VM Host Component Documentation

## Overview

The `010-vm-host` component deploys a Linux Virtual Machine in Azure with all necessary networking infrastructure. This VM serves as a host for edge deployments, particularly for running an Arc-connected K3s Kubernetes cluster. This documentation provides detailed information about the component's structure, functionality, and usage patterns.

## Component Structure

```text
010-vm-host/
├── terraform/              # Core Terraform implementation
│   ├── main.tf             # Primary resource definitions
│   ├── variables.core.tf   # Required core variables (strings, numbers, etc.)
│   ├── variables.deps.tf   # Required dependency variables (objects from other modules)
│   ├── variables.tf        # Optional variables with defaults
│   ├── outputs.tf          # Output values
│   ├── versions.tf         # Provider requirements
│   ├── README.md           # Auto-generated TF documentation
│   └── tests/              # Terraform tests
│       ├── vm.tftest.hcl   # VM creation tests
│       └── setup/          # Test setup helpers
│          └── main.tf      # Test setup helper
├── ci/                     # CI/CD configuration
│   └── terraform/          # CI-specific Terraform - wrapper for deployment
│       ├── main.tf         # Simple wrapper for CI deployment
│       └── variables.tf    # Variables for CI deployment
│       └── versions .tf    # Terraform provider requirements
└── README.md               # High-level component documentation
```

## Core Functionality

### Resources Created

This component creates the following Azure resources:

- Virtual Network with subnet
- Network Security Group
- Public IP(s) with DNS label
- Network Interface(s)
- Linux Virtual Machine(s) (Ubuntu 22.04 LTS)
- SSH key pair (stored locally for access)

### Key Features

1. **Scalable VM Deployment**: Supports creating multiple VMs via the `vm_count` variable
2. **User Identity Integration**: Can attach a user-assigned managed identity for Arc onboarding
3. **Secure Access**: Generates SSH keys for secure VM access
4. **Customizable VM Size**: Configurable VM size via `vm_sku_size` variable (default: Standard_D8s_v3)
5. **Dynamic Naming**: Consistent resource naming using prefix and environment variables

## Usage Guidelines

### Required Input Variables

- `resource_prefix`: Prefix for all resources in this module
- `location`: Azure region for deployment
- `environment`: Environment designation (dev, test, prod)
- `aio_resource_group`: Resource group object where resources will be deployed

### Optional Input Variables

- `vm_username`: Username for VM access (defaults to resource_prefix if not specified)
- `vm_sku_size`: VM size (default: Standard_D8s_v3)
- `vm_count`: Number of VMs to create (default: 1)
- `arc_onboarding_user_assigned_identity`: User identity for Arc onboarding (optional)
- `instance`: Instance identifier for resource naming (default: "001")

### Testing

The component includes tests that verify:

1. Default VM creation with proper SSH key permissions
2. VM creation with user-assigned identity

Tests use a setup module to create randomized resource prefixes for isolation.

### Integration Points

1. **Arc Integration**: This component creates VMs that can be onboarded to Azure Arc via user-assigned identities
2. **SSH Access**: Outputs include SSH command and key path for VM access
3. **Kubernetes**: Designed to host K3s cluster deployments

## Example Usage in CI/CD

The CI configuration demonstrates how to deploy this component with proper references to existing resource groups and user-assigned identities.

## Best Practices for Modification

1. **Always run tests**: Run `terraform test` before committing changes
2. **Maintain naming conventions**: Follow the established naming pattern using resource prefix, component type, and environment
3. **Update documentation**: Keep the README and TF docs updated when adding features
4. **Consider security**: When adding new ingress rules or access points, ensure they follow security best practices
5. **Resource sizing**: When modifying default VM sizes, balance performance needs with cost
6. **Output consistency**: Maintain output schema consistency for dependent modules

## Common Issues and Troubleshooting

1. **SSH Access Issues**:
   - Ensure JIT access is enabled in Azure
   - Verify SSH key permissions (should be 600)
   - Check NSG rules allow port 22 traffic

2. **Identity Issues**:
   - Verify the user-assigned identity exists and has proper role assignments
   - Check identity ID format in the configuration

3. **Networking**:
   - Ensure subnet address space doesn't conflict with other networks
   - Verify DNS propagation if using domain names

## Enhancement Opportunities

1. Add support for custom VM images
2. Implement more advanced networking options (private endpoints, service endpoints)
3. Add configuration for additional data disks
4. Implement backup policy integration
5. Add auto-shutdown options for cost savings in dev/test environments

---

*This document was generated or last updated on [2025-03-18] by GitHub Copilot model Claude 3.7 Thinking (Preview)*
