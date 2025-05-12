# Bicep Instructions

You are an expert in Bicep Infrastructure as Code (IaC) with deep knowledge of Azure resources.
Reference `general.instructions.md` for details on components and blueprints.

Bicep is a domain-specific language (DSL) for deploying Azure resources declaratively. This document provides standards and conventions for Bicep development in this project.

You will ALWAYS think hard about bicep instructions and established conventions.

<!-- <table-of-contents> -->
## Table of Contents

- [Bicep CI Directories](#bicep-ci-directories) <!-- <example-bicep-ci> -->
- [Bicep Component Structure](#bicep-component-structure) <!-- <example-bicep-component-structure> -->
- [Bicep Component Files Organization](#bicep-component-files-organization)
- [Bicep Blueprint Structure](#bicep-blueprint-structure) <!-- <example-bicep-blueprint-structure> -->
- [Bicep Coding Conventions](#bicep-coding-conventions)
  - [API Versioning](#api-versioning)
  - [Reference and Validation](#reference-and-validation)
  - [Bicep General Conventions](#bicep-general-conventions) <!-- <bicep-general-conventions> -->
    - [File and Naming Standards](#file-and-naming-standards)
    - [Documentation and Comments](#documentation-and-comments)
    - [Parameters and Types](#parameters-and-types)
    - [Resource Naming](#resource-naming)
    - [Outputs](#outputs)
    - [Resource Scoping](#resource-scoping)
    - [Component-Specific Conventions](#component-specific-conventions)
    - [Enforcing Conventions](#enforcing-conventions)
  - [Bicep Metadata and Documentation](#bicep-metadata-and-documentation)
  - [Bicep Type System](#bicep-type-system)
    - [Core Types](#core-types) <!-- <types-core-bicep-example> -->
    - [Component Types](#component-types) <!-- <types-bicep-example> -->
  - [Bicep File Organization and Structure](#bicep-file-organization-and-structure)
    - [Main File Organization](#main-file-organization) <!-- <component-main-bicep-example> -->
    - [Parameters Organization](#parameters-organization)
    - [Outputs Organization](#outputs-organization)
<!-- </table-of-contents> -->

## Bicep CI Directories

Example `ci/main.bicep` that only requires common parameters:

<!-- <example-bicep-ci> -->
```bicep
import * as core from '../../bicep/types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Modules
*/

module ci '../../bicep/main.bicep' = {
  name: '${deployment().name}-ci'
  params: {
    common: common
  }
}
```
<!-- </example-bicep-ci> -->

## Bicep Component Structure

<!-- <example-bicep-component-structure> -->
```plain
src/
  100-edge/
    110-iot-ops/
      bicep/               # This is a COMPONENT MODULE
        main.bicep         # Main orchestration file
        types.bicep        # Component-specific types with defaults
        types.core.bicep   # Core shared types (Common)
        README.md          # README file component bicep/ directory is automatically generated, never by AI
        modules/
          iot-ops-init.bicep          # This is an INTERNAL MODULE
          iot-ops-instance.bicep      # This is an INTERNAL MODULE
          iot-ops-instance-post.bicep # This is an INTERNAL MODULE
          role-assignment.bicep       # This is an INTERNAL MODULE
      ci/
        bicep/             # This is a CI BICEP DIRECTORY
          main.bicep       # CI wrapper for deployment
```
<!-- </example-bicep-component-structure> -->

## Bicep Component Files Organization

ALWAYS use consistent file organization (not limited to these files):

1. `main.bicep` - Primary resource definitions and orchestration
2. `types.core.bicep` - Core type definitions (e.g., Common type)
3. `types.bicep` - Component-specific type definitions and defaults
4. `modules/` - Directory containing internal modules

## Bicep Blueprint Structure

Blueprints compose multiple components into complete IaC stamps:

<!-- <example-bicep-blueprint-structure> -->
```plain
blueprints/
  full-multi-node-cluster/
    bicep/               # This is a BLUEPRINT MODULE
      main.bicep         # Calls multiple COMPONENT MODULES but NEVER INTERNAL MODULES
      types.core.bicep   # Core types for the blueprint
    README.md            # Contains important deployment instructions
```
<!-- </example-bicep-blueprint-structure> -->

## Bicep Coding Conventions

### API Versioning

- DO use the same API version for identical resource types throughout the codebase
- DO use the existing API version when modifying existing resources
- DO use the latest API version for new resources
- DO update resources to use the latest API version when making significant changes
- DO use the tool `#azureBicepGetResourceSchema` to get the latest API version

Example of API version standardization:

```bicep
// Before:
resource sseIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
}

// Somewhere else in the codebase...
resource aioIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
}

// After (standardized to latest API version):
resource sseIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
}

// Somewhere else in the codebase...
resource aioIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
}
```

### Reference and Validation

- ALWAYS search the codebase for existing Bicep resources to use as a reference when editing
- When no reference exists:
  1. Use VS Code's API Tooling for getting the ARM reference and version information
  2. Fallback to using `#fetch` to read the Microsoft documentation: `https://learn.microsoft.com/azure/templates/{provider-namespace}/{resource-type}`
     - Example: `https://learn.microsoft.com/azure/templates/microsoft.managedidentity/userassignedidentities`
- ALWAYS verify VS Code's information, warnings, and errors after making edits
  - Fix all validation issues before committing changes

### Bicep General Conventions

<!-- <bicep-general-conventions> -->
#### File and Naming Standards

- DO use `kebab-case` for file and folder names
- DO use `camelCase` for parameter names and `PascalCase` for type names
- DO add metadata information at the top of each file
- NEVER use hardcoded values for resource names, locations, etc.

#### Documentation and Comments

- DO use the `@description()` decorator for all parameters and types
  - DO provide descriptive short descriptions that end with a period
  - DO explain non-obvious behaviors: `'The description. (Updates a something not obvious when set)'`
- DO organize your file with clear section headers using `/* */` comments
- DO add helpful comments to clarify complex logic or reference documentation

#### Parameters and Types

- DO use and update `types.bicep` to improve usability by creating or updating `type`s for related parameters
- DO use `??` and/or `.?` instead of ternary operators with `empty()` or null checks
- DO organize parameters together based on their function grouping
  - DO alphabetically sort parameters within each function grouping
  - DO name each function grouping with a `/* */` comment
- DO start boolean parameters with `should` or `is`
- DO NOT add defaults to required parameters
- DO use the safe access operator `.?` or `??` for accessing nullable properties
- DO NOT default a parameter to `''` empty string; use `null` instead
- DO use `@secure()` for sensitive parameters
- ALWAYS prefer simple name parameters with existing resources over complex object parameters:
  - DO the following:

  ```bicep
  param identityName string?
  resource identity '...@2024-11-30' existing = if (!empty(identityName)) {
    name: identityName!
  }
  ```

  - AVOID the following:

  ```bicep
  param identity object // Complex type requiring multiple properties
  ```

#### Resource Naming

- DO follow [Azure resource naming conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- DO follow these patterns for default resource names:
  - Hyphens allowed: `{resource_abbreviation}-${common.resourcePrefix}-{optional_extra}-${common.environment}-${common.instance}`
  - Hyphens not allowed: `{resource_abbreviation}${common.resourcePrefix}{optional_extra}${common.environment}${common.instance}`
  - Name length restriction: `'{resource_abbreviation}${uniqueString(common.resourcePrefix, {optional_extra}, common.environment, common.instance)}'`
- Examples:
  - `id-${common.resourcePrefix}-arc-${common.environment}-${common.instance}` for User Assigned Identity
  - `kv-${common.resourcePrefix}-${common.environment}-${common.instance}` for Key Vault
  - `st${uniqueString(common.resourcePrefix, common.environment, common.instance)}` for Storage Account

#### Outputs

- DO provide helpful descriptions with `@description()`
- DO use conditional expressions for outputs that depend on conditional resources
- DO follow a consistent order in output declarations
- DO make outputs nullable when appropriate using the `?` type modifier

#### Resource Scoping

- DO assume `targetScope = 'resourceGroup'` EXCEPT FOR blueprints
- DO NOT set `scope:` with any `id` string
  - DON'T use: `scope: resourceGroup(split(arcConnectedCluster.id, '/')[4])`
  - DO use: `scope: arcConnectedCluster` (using the resource name to create an `existing` resource)
- DO use `existing =` for existing resources
- DO create resources in `existing` resources instead of setting `scope:`
- DO use an internal `module` to change resource group scope, e.g., `scope: resourceGroup(arcConnectedClusterResourceGroupName)`

#### Component-Specific Conventions

For Components ONLY:

- DO provide defaults for parameters that can have defaults
- DO place resources in `main.bicep`
- NEVER reference another component directly
  - EXPECT other component resource outputs to be provided as parameters
- NEVER reference another component's internal modules directly
  - EXPECT other component's internal module resources to be provided via outputs
- DO receive resource names to use with `existing` INSTEAD OF resource ids

For Internal modules ONLY:

- NEVER provide defaults for parameters
  - Components should include parameters and defaults for internal modules
  - Components should pass defaults to internal modules
- DO place resources in `{component_name}/bicep/modules/{module_name}.bicep`
- NEVER use a component or another component's internal modules

#### Enforcing Conventions

You should ALWAYS ensure bicep conventions are being followed:

- CONTINUOUSLY evaluate if your changes follow bicep conventions
- Make changes to any and all places that are not following bicep conventions
- If a user's change conflicts with any bicep convention, suggest an update to the conventions
  - DON'T make any changes to the bicep conventions yourself
  - ONLY suggest an exact change as a response to the user
<!-- </bicep-general-conventions> -->

### Bicep Metadata and Documentation

Every Bicep file must include metadata at the top:

```bicep
metadata name = 'Component or Blueprint Name'
metadata description = 'Description of what this component does and how it works.'

// Imports come after metadata...
```

Metadata serves as documentation for the module and helps with module discoverability and comprehension. This is required for all Bicep files.

### Bicep Type System

A robust type system enhances code reusability, increases consistency, and improves documentation.

#### Core Types

The `Common` type in `types.core.bicep` provides standardized parameters used across all components:

<!-- <types-core-bicep-example> -->
```bicep
@export()
@description('Common settings for the components.')
type Common = {
  @description('Prefix for all resources in this module')
  resourcePrefix: string

  @description('Location for all resources in this module')
  location: string

  @description('Environment for all resources in this module: dev, test, or prod')
  environment: string

  @description('Instance identifier for naming resources: 001, 002, etc...')
  instance: string
}
```
<!-- </types-core-bicep-example> -->

#### Component Types

Component-specific types in `types.bicep` should follow these conventions:

- DO use `@export()` for all types and default values
- DO use `@description()` following the general bicep conventions
- DO use `@secure()` for sensitive parameters
- DO provide sensible defaults for all types next to their type definition
- DO use type literals (e.g., 'K3s' | 'K8s') for parameters with known values

<!-- <types-bicep-example> -->
```bicep
@export()
@description('The settings for the Azure IoT Operations Extension.')
type AioExtension = {
  @description('The common settings for the extension.')
  release: Release

  settings: {
    @description('The namespace in the cluster where Azure IoT Operations will be installed.')
    namespace: string

    @description('The distro for Kubernetes for the cluster.')
    kubernetesDistro: 'K3s' | 'K8s' | 'MicroK8s'

    @description('The length of time in minutes before an operation for an agent timesout.')
    agentOperationTimeoutInMinutes: int
  }
}

@export()
var aioExtensionDefaults = {
  release: {
    version: '1.0.9'
    train: 'stable'
  }
  settings: {
    namespace: 'azure-iot-operations'
    kubernetesDistro: 'K3s'
    agentOperationTimeoutInMinutes: 120
  }
}
```
<!-- </types-bicep-example> -->

### Bicep File Organization and Structure

#### Main File Organization

For all `main.bicep` files, follow this consistent organization:

1. **Required**: Metadata and imports at the top
2. Common parameters section with `common` parameter of type `core.Common`
3. Component-specific parameters grouped by functionality
4. Local variables (if needed)
5. Resources section
6. Modules section
7. Outputs section

Each section should be clearly separated with comment headers using `/* */` notation.

<!-- <component-main-bicep-example> -->
```bicep
metadata name = 'Azure IoT Operations'
metadata description = 'Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.'

import * as core from './types.core.bicep'
import * as types from './types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('The resource name for the Arc connected cluster.')
param arcConnectedClusterName string

@description('Whether to create the example resource for outputs.')
param shouldCreateExample string

/*
  Azure IoT Operations Init Parameters
*/

@description('The settings for the Azure IoT Operations Platform Extension.')
param aioPlatformConfig types.AioPlatformExtension = types.aioPlatformExtensionDefaults

/*
  Storage Account Parameters
*/

@description('The name for the Storage Account used by the Schema Registry.')
param storageAccountName string = shouldCreateStorageAccount
  ? 'st${uniqueString(resourceGroup().id)}'
  : fail('storageAccountName required when shouldCreateStorageAccount is false')

/*
  Schema Registry Parameters
*/

@description('The name for the ADR Schema Registry.')
param schemaRegistryName string = 'sr-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('The ADLS Gen2 namespace for the ADR Schema Registry.')
param schemaRegistryNamespace string = 'srns-${common.resourcePrefix}-${common.environment}-${common.instance}'

/*
  Secret Sync and Key Vault Parameters
*/

@description('The name of the Key Vault for Secret Sync. (Required when providing sseIdentityName)')
param sseKeyVaultName string

@description('The name of the User Assigned Managed Identity for Secret Sync.')
param sseIdentityName string

@description('The name of the Resource Group for the Key Vault for Secret Sync. (Required when providing sseIdentityName)')
param sseKeyVaultResourceGroupName string = resourceGroup().name

@description('Whether to assign roles for Key Vault to the provided Secret Sync Identity.')
param shouldAssignSseKeyVaultRoles bool = true

/*
  Resources
*/

resource example 'example@1.2.3' = if (shouldCreateExample) {
  name: 'example-name'
}

/*
  Modules
*/

module exampleInternalModule 'modules/example-internal-module.bicep' = {
  name: '${deployment().name}-eim0'
  params: {
    aioPlatformConfig: aioPlatformConfig
    common: common
    storageAccountName: storageAccountName
    schemaRegistryName: schemaRegistryName
    schemaRegistryNamespace: schemaRegistryNamespace
    storageAccountContainerUrl: 'https://${storageAccountName}.blob.${environment().suffixes.storage}/${schemaContainerName}'
  }
}

module roleAssignment 'modules/role-assignment.bicep' = if (shouldAssignKeyVaultRoles) {
  name: '${deployment().name}-ra0'
  scope: resourceGroup(sseKeyVaultResourceGroupName)
  params: {
    keyVaultName: sseKeyVaultName
    sseUserAssignedIdentityName: sseIdentityName
  }
}

/*
  Outputs
*/

@description('The ADR Schema Registry Name.')
output exampleOutputValue string? = shouldCreateExample ? example.properties.value : null

@description('The ADR Schema Registry Name.')
output schemaRegistryName string? = exampleInternalModule.outputs.schemaRegistryName

@description('The Storage Account Name.')
output storageAccountName string = exampleInternalModule.outputs.storageAccountName ?? storageAccountName
```
<!-- </component-main-bicep-example> -->

#### Parameters Organization

DO organize parameters as follows:

1. Common parameters first
2. Required parameters with no defaults
3. Optional parameters grouped by functionality
4. Each group should have a clear comment header
5. Parameters within each group should be alphabetically sorted

#### Outputs Organization

DO organize outputs as follows:

1. Group outputs by functionality using comment headers
2. Within each group, sort outputs alphabetically
3. Include clear descriptions using `@description()`
4. Use nullable types (`string?`) for conditional outputs
5. Use the null coalescing operator (`??`) for fallback values
