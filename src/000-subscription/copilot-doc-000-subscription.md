# Azure Subscription Resource Provider Management

## Overview

This component contains scripts and utilities for managing Azure resource providers at the subscription level. The registration of specific Azure resource providers is a prerequisite for deploying Azure IoT Operations and related services. This component provides cross-platform tooling to automate the registration and unregistration process.

## Key Components

### Registration Scripts

- `register-azure-providers.sh` - Bash script for registering Azure resource providers
- `register-azure-providers.ps1` - PowerShell equivalent with the same functionality
- `register-azure-providers.Tests.ps1` - Pester tests for the PowerShell implementation

### Unregistration Scripts

- `unregister-azure-providers.sh` - Bash script for unregistering Azure resource providers

### Required Providers

The default set of resource providers needed for Azure IoT Operations deployments is defined in:

- `aio-azure-resource-providers.txt`

This includes providers for:

- Kubernetes and edge computing: `Microsoft.ExtendedLocation`, `Microsoft.Kubernetes`, `Microsoft.KubernetesConfiguration`
- IoT Operations: `Microsoft.IoTOperations`, `Microsoft.DeviceRegistry`
- Security: `Microsoft.SecretSyncController`
- Monitoring and alerting: `Microsoft.AlertsManagement`, `Microsoft.Monitor`, `Microsoft.Dashboard`, `Microsoft.Insights`, `Microsoft.OperationalInsights`

## Technical Implementation

### Common Features

- Real-time visual feedback with color-coded terminal output
- Progress tracking with state transitions (NotRegistered → Registering → Registered)
- Support for custom provider lists via text files
- Proper error handling and usage guidance
- Azure CLI dependency validation

### Architecture

These scripts serve as prerequisites for the larger IaC deployment framework. They ensure that all necessary resource providers are available before the actual infrastructure deployment begins. The registration process can take several minutes, and these scripts provide visual feedback during this wait time.

## Usage Context

This component should be executed early in the deployment process, typically before any Terraform operations. Only users with Contributor or Owner roles on the subscription can register resource providers.

## Dependencies

- Azure CLI
- Subscription-level permissions (Contributor or Owner role)

---

*This document was generated or last updated on [2025-03-18] by GitHub Copilot model Claude 3.7 Thinking (Preview)*
