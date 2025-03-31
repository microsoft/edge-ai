# Onboard Infrastructure Requirements - Bicep

This Bicep implementation creates the required resources needed for an edge IaC deployment, including:

- Resource Group creation or use of an existing Resource Group
- Onboarding Identity (User Assigned Managed Identity or Service Principal) with Azure Arc permissions

## Parameters

### Common Parameters

| Parameter | Type   | Description                                                                    | Required |
|-----------|--------|--------------------------------------------------------------------------------|:--------:|
| common    | object | Common settings including resource prefix, location, environment, and instance |   Yes    |

### Resource Group Configuration

| Parameter           | Type   | Description                                                | Default                           |
|---------------------|--------|------------------------------------------------------------|-----------------------------------|
| resourceGroupConfig | object | Settings for the resource group (shouldCreate, name, tags) | See default values in types.bicep |

### Onboard Identity Configuration

| Parameter             | Type   | Description                                                       | Default                           |
|-----------------------|--------|-------------------------------------------------------------------|-----------------------------------|
| onboardIdentityConfig | object | Settings for the onboarding identity (shouldCreate, identityType) | See default values in types.bicep |

## Outputs

| Output                               | Type   | Description                                                                                          |
|--------------------------------------|--------|------------------------------------------------------------------------------------------------------|
| arcOnboardingUserManagedIdentityId   | string | The User Assigned Managed Identity ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions   |
| arcOnboardingUserManagedIdentityName | string | The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions |
| arcOnboardingSpClientId              | string | The Service Principal Client ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions         |
| arcOnboardingSpClientSecret          | string | The Service Principal Secret used for automation (sensitive value)                                   |
| arcOnboardingUserAssignedIdentity    | object | The User Assigned Managed Identity with "Kubernetes Cluster - Azure Arc Onboarding" permissions      |
| resourceGroup                        | object | The Resource Group for the deployment                                                                |

## Example Usage

```bicep
// Define common parameters
param common = {
  resourcePrefix: 'myprefix'
  location: 'eastus2'
  environment: 'dev'
  instance: '001'
}

// Deploy the onboarding requirements
module onboardReqs './main.bicep' = {
  name: 'onboardingRequirements'
  params: {
    common: common
    resourceGroupConfig: {
      shouldCreate: true
      name: 'my-custom-rg'
      tags: {
        Environment: 'Development'
        Owner: 'Edge Team'
      }
    }
    onboardIdentityConfig: {
      shouldCreate: true
      identityType: 'id' // Use 'id' for User Assigned Managed Identity or 'sp' for Service Principal
    }
  }
}

// Reference outputs
output resourceGroupName string = onboardReqs.outputs.resourceGroup.name
output uamiId string = onboardReqs.outputs.arcOnboardingUserManagedIdentityId
```

## Module Structure

- `main.bicep`: Core implementation that orchestrates resource creation
- `types.core.bicep`: Common types shared across components
- `types.bicep`: Component-specific types and default values
- `modules/onboard-identity.bicep`: Module for creating onboarding identity (UAMI or SP)
