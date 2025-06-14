---
title: New Environment Onboard Requirements
description: Component for onboarding a new environment and includes IaC for creating resources that are needed for an edge deployment including Azure Resource Group, User Assigned Managed Identity, and Service Principal
author: Edge AI Team
ms.date: 06/07/2025
ms.topic: reference
keywords:
  - azure resource group
  - managed identity
  - service principal
  - environment onboarding
  - edge deployment
  - terraform
  - bicep
  - infrastructure as code
estimated_reading_time: 4
---

## New Environment Onboard Requirements

Component for onboarding a new environment and includes IaC for creating resources that are needed for an
edge deployment.

This includes the following:

- Azure Resource Group (can create new or use existing)
- User Assigned Managed Identity for a VM Host
- Service Principal for automated cluster setup and Azure Arc connection

## Using Existing Resource Groups

This component supports two modes of operation:

1. **Default mode**: Creates a new Azure Resource Group with a name based on the provided parameters
2. **Existing Resource Group mode**: Uses an existing Azure Resource Group instead of creating a new one

### Terraform Implementation

To use an existing resource group, set the following parameters:

```terraform
module "cloud_resource_group" {
  source = "../../../src/000-cloud/000-resource-group/terraform"

  // Required parameters
  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix

  // Specify an existing resource group
  resource_group_name         = "my-existing-resource-group" // Optional: If not specified, the default name format will be used
}
```

### Bicep Implementation

To use an existing resource group, set the following parameters:

```bicep
module cloudResourceGroup '../../../src/000-cloud/000-resource-group/bicep/main.bicep' = {
  name: '${deployment().name}-crg0'
  params: {
    common: common
    useExistingResourceGroup: true
    resourceGroupName: 'my-existing-resource-group' // Optional: If not specified, the default name format will be used
  }
}
```

### Error Handling

When `useExistingResourceGroup` is set to `true` (Bicep):

- The component will attempt to look up the resource group with the provided name (or the generated name if none is specified)
- If the resource group doesn't exist, deployment will fail with an error message indicating the resource group couldn't be found
- To avoid errors, ensure that the resource group exists before deployment or use the default mode to create a new resource group

### Required Permissions

When using an existing resource group, ensure:

- The service principal or user account running the deployment has at least `Contributor` access to the existing resource group
- For Terraform deployments, the service principal needs `Reader` access to query the existing resource group
- For Bicep deployments, the deployment identity requires `Microsoft.Resources/subscriptions/resourceGroups/read` permission

### Considerations for Downstream Resources

When using an existing resource group:

- All downstream resources will be deployed to the existing resource group
- Naming conventions should be consistent to avoid conflicts
- The location of the existing resource group will be used for location-specific resources
- Existing resources in the resource group might cause name conflicts or unexpected interactions
- Resource tags from the existing resource group will not be modified

## Terraform

Refer to [Terraform Components - Getting Started](../README.md#terraform-components---getting-started) for
deployment instructions.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
