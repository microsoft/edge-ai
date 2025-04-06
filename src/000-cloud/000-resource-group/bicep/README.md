<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Onboard Infrastructure Prerequisites
  
Creates the required resources needed for an edge IaC deployment.  

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|[_2.Common](#user-defined-types)|n/a|yes|
|onboardIdentityConfig|Settings for the onboarding identity.|[_1.OnboardIdentitySettings](#user-defined-types)|[variables('_1.onboardIdentityDefaults')]|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|onboardIdentity|Microsoft.Resources/deployments|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|onboardIdentity|Creates an identity (User Assigned or Service Principal) with necessary permissions for Azure Arc onboarding.|

## Module Details

### onboardIdentity
  
Creates an identity (User Assigned or Service Principal) with necessary permissions for Azure Arc onboarding.  

#### Parameters for onboardIdentity

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|[_2.Common](#user-defined-types)|n/a|yes|
|identityType|The identity type to use for onboarding the cluster to Azure Arc.|[_1.OnboardIdentityType](#user-defined-types)|n/a|yes|

#### Resources for onboardIdentity

|Name|Type|API Version|
| :--- | :--- | :--- |
|userAssignedIdentity|Microsoft.ManagedIdentity/userAssignedIdentities|2024-11-30|
|arcOnboardingRoleAssignment|Microsoft.Authorization/roleAssignments|2022-04-01|
|arcOnboardingApp|Microsoft.Graph/applications@v1.0||
|arcOnboardingClientSp|Microsoft.Graph/servicePrincipals@v1.0||

#### Outputs for onboardIdentity

|Name|Type|Description|
| :--- | :--- | :--- |
|userManagedIdentityId|string|The User Assigned Managed Identity ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|
|userManagedIdentityName|string|The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|
|userAssignedIdentity|object|The User Assigned Managed Identity with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|
|servicePrincipalClientId|string|The Service Principal App (Client) ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|

## User Defined Types

### `_1.OnboardIdentitySettings`
  
Settings for onboarding identity creation.  

|Property|Type|Description|
| :--- | :--- | :--- |
|shouldCreate|bool|Should create either a User Assigned Managed Identity or Service Principal to be used with onboarding a cluster to Azure Arc.|
|identityType|[_1.OnboardIdentityType](#user-defined-types)|Identity type to use for onboarding the cluster to Azure Arc.|

### `_1.OnboardIdentityType`
  
Identity type to use for onboarding the cluster to Azure Arc. Allowed values: "id" (User Assigned Managed Identity) or "sp" (Service Principal)  

### `_2.Common`
  
Common settings for the components.  

|Property|Type|Description|
| :--- | :--- | :--- |
|resourcePrefix|string|Prefix for all resources in this module|
|location|string|Location for all resources in this module|
|environment|string|Environment for all resources in this module: dev, test, or prod|
|instance|string|Instance identifier for naming resources: 001, 002, etc...|

## Outputs

|Name|Type|Description|
| :--- | :--- | :--- |
|arcOnboardingUserManagedIdentityId|string|The User Assigned Managed Identity ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|
|arcOnboardingUserManagedIdentityName|string|The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|
|arcOnboardingSpClientId|string|The Service Principal Client ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->
