---
title: Security and Identity Component
description: Foundational security infrastructure for Azure IoT Operations including managed identities, Azure Key Vault, Schema Registry, and role-based access control
author: Edge AI Team
ms.date: 2025-06-07
ms.topic: reference
keywords:
  - security
  - identity
  - azure iot operations
  - managed identity
  - azure key vault
  - schema registry
  - rbac
  - secret sync
  - arc onboarding
  - terraform
  - bicep
estimated_reading_time: 3
---

## Security and Identity Component

This component establishes the foundational security infrastructure required for Azure IoT Operations deployments. It creates the necessary cloud resources that enable secure communication, secret management, and identity-based access control across the Edge AI Accelerator solution.

## Purpose and Role

The Security and Identity component serves as the security foundation for the entire Edge AI Accelerator:

- **Identity Management**: Creates managed identities for various Azure IoT Operations services
- **Secret Management**: Provides secure storage and sync of secrets to edge devices
- **Schema Management**: Establishes device registry and schema validation capabilities
- **Access Control**: Implements role-based access control for all solution components

## Component Resources

This component creates the following Azure resources:

### Core Infrastructure

- **Azure Key Vault**: Central secret store with managed identity access
- **Azure Device Registry Schema Registry**: Schema validation for device communications
- **Storage Account**: Backing storage for the Schema Registry

### Identity and Access Management

- **Arc Onboarding Identity**: User-assigned managed identity for onboarding edge clusters to Azure Arc
- **AIO User Managed Identity**: Primary identity for Azure IoT Operations services
- **Secret Sync Identity**: Managed identity for the Secret Sync Extension to access Key Vault
- **AIO Edge Application**: Azure AD application and service principal for edge authentication

### Role Assignments

- Appropriate RBAC assignments for each managed identity to access required resources
- Key Vault access policies for secret management operations

## Integration with Other Components

This component provides essential services to other parts of the solution:

- **Edge Components**: Managed identities enable secure Arc onboarding and service authentication
- **Messaging Component**: Identities provide secure access to Event Grid and Event Hubs
- **Data Component**: Enables secure access to storage and analytics services
- **All Components**: Secret Sync Extension distributes secrets securely to edge devices

## Deployment Options

### Terraform

Refer to [Terraform Components - Getting Started](../README.md#terraform-components---getting-started) for deployment instructions.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

### Bicep

Refer to [Bicep Components - Getting Started](../README.md#bicep-components---getting-started) for deployment instructions.

Learn more about the required configuration by reading the [./bicep/README.md](./bicep/README.md)

## Security Considerations

- All managed identities follow the principle of least privilege
- Key Vault access is restricted to specific identities and administrators
- Schema Registry provides validation to ensure secure device communications
- Secret Sync Extension enables secure distribution of secrets to edge without storing them in configuration

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
