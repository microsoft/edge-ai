---
title: Security and Identity Terraform Modules
description: Reusable Terraform modules for creating Azure IoT Operations cloud requirements including managed identities, Azure Key Vault, and role assignments
author: Edge AI Team
ms.date: 06/07/2025
ms.topic: reference
keywords:
  - terraform modules
  - security
  - identity
  - azure iot operations
  - managed identity
  - azure key vault
  - rbac
  - role assignments
  - infrastructure as code
estimated_reading_time: 2
---

## Security and Identity Terraform Modules

This directory contains reusable Terraform modules for creating the security and identity infrastructure required by Azure IoT Operations.

## Available Modules

### Identity Module (`./identity`)

Creates User Assigned Managed Identities and Azure Active Directory service principals required for Azure IoT Operations:

- **Arc Onboarding Identity**: Used to onboard edge clusters to Azure Arc
- **AIO User Managed Identity**: Primary identity for Azure IoT Operations services
- **Secret Sync Identity**: Used by the Secret Sync Extension to access Azure Key Vault
- **AIO Edge Application**: Azure AD application and service principal for edge authentication

### Key Vault Module (`./key-vault`)

Creates and configures Azure Key Vault resources for secure secret management:

- **Azure Key Vault**: Central secret store for the solution
- **Access Policies**: Configured access for managed identities and administrators
- **RBAC Assignments**: Role-based access control for Key Vault operations

## Module Usage

These modules are designed to be used together as part of the security and identity component. They provide:

- **Separation of concerns**: Each module handles a specific aspect of security infrastructure
- **Reusability**: Modules can be referenced by other components that need similar resources
- **Consistency**: Standardized naming and tagging conventions across all resources

## Dependencies

The modules in this directory have dependencies on each other:

- The Key Vault module references outputs from the Identity module for access policy configuration
- Both modules share common input variables for consistent resource naming and location

For detailed information about each module's inputs, outputs, and resources, refer to the individual module README files.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
