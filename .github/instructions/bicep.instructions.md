---
applyTo: '**/*.bicep*'
---
# Bicep IaC Conventions and Best Practices

You are an expert in Bicep Infrastructure as Code (IaC) with deep knowledge of Azure resources. When writing or evaluating Bicep code, always follow the conventions in this document.

## Repository Structure

This repository is organized with the following key directories:

1. **Source Components** (`src/`) - Individual reusable infrastructure components:
   - `000-cloud/` - Cloud-based resources (Resource Groups, Identity, Storage, etc.)
   - `100-edge/` - Edge-based resources (IoT Operations, CNCF clusters, etc.)
   - `500-application/` - Application resources and source code
   - `900-tools-utilities/` - Tools and utilities (YAML, Helm charts, etc.)

2. **Blueprints** (`blueprints/`) - End-to-end solutions that combine components:
   - `full-single-node-cluster/` - Single-node AIO deployment
   - `full-multi-node-cluster/` - Multi-node HA AIO deployment
   - `only-output-cncf-cluster-script/` - Script-only deployment

## Module Types: Component Modules vs. Internal Modules

### Component Modules

Component Modules are the top-level, standalone modules that provide a specific capability or resource set within the repository. They are located under `src/000-grouping/000-component/bicep`, where `000-grouping` is the meta grouping (like `cloud` or `edge`), and `000-component` is the Component Module.

**Characteristics of Component Modules:**

- Located directly under a component directory in `src/` (e.g., `src/100-edge/110-iot-ops/bicep/`)
- Exposed to be called from **Blueprint** modules
- Represent a complete, self-contained functional unit (e.g., Resource Group, CNCF Cluster, IoT Ops)
- Can use their own Internal Modules but NEVER reference other Component Modules
- Usually deployed in a specific order based on their directory naming
- Have comprehensive metadata and documentation
- May include a corresponding `ci/bicep` directory for CI/CD pipeline integration

**Example Component Module path:**

```plain
src/100-edge/110-iot-ops/bicep/
```

### Internal Modules

Internal Modules are subordinate, reusable modules that are only used within their parent Component Module. They help organize and modularize the Component Module's implementation.

**Characteristics of Internal Modules:**

- Located in the `modules` subdirectory of a Component Module (e.g., `src/100-edge/110-iot-ops/bicep/modules/iot-ops-instance.bicep`)
- NEVER called directly from Blueprints or other Component Modules
- Implement specific functionality within the scope of their parent Component
- Have narrower scope and focused responsibility
- Include metadata name and description at the top of the file

**Example Internal Module path:**

```plain
src/100-edge/110-iot-ops/bicep/modules/iot-ops-instance.bicep
```

### CI Bicep Directories

CI Bicep directories are wrapper directories used for CI/CD integration that leverage Component Modules:

**Characteristics of CI Bicep Directories:**

- Located at `<component>/ci/bicep/` (e.g., `src/100-edge/110-iot-ops/ci/bicep/`)
- Contains simple code that calls the parent Component Module with default/test configurations
- Used for individual component testing and verification in CI/CD pipelines
- Acts as a thin wrapper for the component, not setting up test resources

Example `ci/main.bicep` that only requires common parameters:

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

module iotOpsCloudReqs '../../bicep/main.bicep' = {
  name: '${deployment().name}-ci'
  params: {
    common: common
  }
}
```

## Component Structure

Each component follows a decimal naming convention for deployment order (e.g., `000-resource-group`, `110-iot-ops`):

```plain
src/
  100-edge/
    110-iot-ops/
      bicep/               # This is a COMPONENT MODULE
        main.bicep         # Main orchestration file
        types.bicep        # Component-specific types with defaults
        types.core.bicep   # Core shared types (Common)
        modules/
          iot-ops-init.bicep          # This is an INTERNAL MODULE
          iot-ops-instance.bicep      # This is an INTERNAL MODULE
          iot-ops-instance-post.bicep # This is an INTERNAL MODULE
          role-assignment.bicep       # This is an INTERNAL MODULE
      ci/
        bicep/             # This is a CI BICEP DIRECTORY
          main.bicep       # CI wrapper for deployment
```

### Component Files Organization

ALWAYS use consistent file organization:

1. `main.bicep` - Primary resource definitions and orchestration
2. `types.core.bicep` - Core type definitions (e.g., Common type)
3. `types.bicep` - Component-specific type definitions and defaults
4. `modules/` - Directory containing internal modules

## Blueprint Structure

Blueprints compose multiple source components into complete solutions:

```plain
blueprints/
  full-multi-node-cluster/
    bicep/               # This is a BLUEPRINT MODULE
      main.bicep         # Calls multiple COMPONENT MODULES but NEVER INTERNAL MODULES
      types.core.bicep   # Core types for the blueprint
    README.md
```

Each blueprint includes:

- `main.bicep` - Main orchestration calling source components
- `types.core.bicep` - Core type definitions
- `README.md` - Deployment instructions

## Bicep Coding Conventions

- ALWAYS use the same API version for the same resource, the `@2023-01-31` part is the API version
- ALWAYS use the existing API version for the same resource
- ALWAYS use the latest API version for the same resource, as an example:
  - If the following code exists in the codebase:

  ```bicep
  resource sseIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  }

  // Somewhere else in the codebase...
  resource aioIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  }
  ```

  - Then the code should be updated to the following:

  ```bicep
  resource sseIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  }

  // Somewhere else in the codebase...
  resource aioIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  }
  ```

- ALWAYS search the codebase for existing Bicep resources to use as a reference when editing
  - WHEN no reference exists, it is important to always use that latest Bicep ARM API reference and version
    - Use VS Code's API Tooling for getting the ARM reference and version information
    - Fallback to navigating and completely reading in the web pages (excluding images) for the following template, `https://learn.microsoft.com/azure/templates/{provider-namespace}/{resource-type}` for the latest Bicep ARM API reference and version
      - e.g., `https://learn.microsoft.com/azure/templates/microsoft.managedidentity/userassignedidentities`
- ALWAYS after making edits, verify VS Codes's information, warnings, and errors for Bicep
  - ALWAYS make any and all corrections, if unable, fallback to these prompt instructions

### General Conventions

- ALWAYS use `kebab-case` for file and folder names
- ALWAYS use `camelCase` for parameter names and `PascalCase` for type names
- ALWAYS add metadata information at the top of each file
- NEVER use hardcoded values for resource names, locations, etc.
- ALWAYS use the `@description()` decorator for all parameters and types
- ALWAYS organize your file with clear section headers using `/*` comments
- ALWAYS use `??` and/or `.?` instead of ternary operators with `empty()` or checks for null.

### Metadata and Documentation

Every Bicep file must include metadata at the top:

```bicep
metadata name = 'Component or Blueprint Name'
metadata description = 'Description of what this component does and how it works.'
```

### Type System

Use a robust type system with the `Common` type in all components:

```bicep
// Example from types.core.bicep
@export()
@description('Common settings for the components.')
type Common = {
  @description('Prefix for all resources in this module')
  resourcePrefix: string

  @description('Location for all resources in this module')
  location: string

  @description('Environment for all resources in this module: dev, test, or prod')
  environment: string?

  @description('Instance identifier for naming resources: 001, 002, etc...')
  instance: string?
}
```

For component-specific types, provide comprehensive type definitions with clear descriptions and defaults:

```bicep
// Example from types.bicep
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

### Resource Structure

Resources should follow this organization:

1. Metadata and imports at the top
2. Common parameters
3. Component-specific parameters grouped by functionality
4. Local variables
5. Resources and modules
6. Outputs

Example:

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

### Module and Component Relationships

IMPORTANT RULES:

- Component Modules (e.g., `src/100-edge/110-iot-ops/bicep/`) NEVER reference other Component Modules
- Component Modules NEVER reference other Component Modules' Internal Modules
- Component Modules ONLY reference their own Internal Modules
- Internal Modules (e.g., `src/100-edge/110-iot-ops/bicep/modules/iot-ops-instance.bicep`) NEVER reference other Component Modules
- Internal Modules NEVER reference other Component Modules' Internal Modules
- Blueprint Modules (e.g., `blueprints/full-multi-node-cluster/bicep/`) ONLY reference Component Modules, NEVER Internal Modules

### Parameters Conventions

- Group parameters with clear section headers:

```bicep
/*
  Azure IoT Operations Init Parameters
*/

@description('The settings for the Azure IoT Operations Platform Extension.')
param aioPlatformConfig types.AioPlatformExtension = types.aioPlatformExtensionDefaults

@description('The settings for the Azure Container Store for Azure Arc Extension.')
param containerStorageConfig types.ContainerStorageExtension = types.containerStorageExtensionDefaults

/*
  Azure IoT Operations Instance Parameters
*/

@description('The settings for the Azure IoT Operations Extension.')
param aioExtensionConfig types.AioExtension = types.aioExtensionDefaults

@description('Whether or not to deploy the Custom Locations Resource Sync Rules for the Azure IoT Operations resources.')
param shouldDeployResourceSyncRules bool = true
```

- Follow these guidelines:
  - ALWAYS provide descriptive `@description()` that ends with a period
  - ALWAYS alphabetically sort parameters within each grouping
  - Boolean parameters SHOULD start with `should` or `is`
  - Required parameters SHOULD NOT have defaults
  - ALWAYS use the safe access operator `.?` for accessing nullable properties
  - NEVER default a parameter to `''` empty string
  - ALWAYS use `?` for parameters that can be empty or null

### Resource Deployment Conventions

When defining module deployments:

1. Use conditional deployments with `if` statements when appropriate
2. Name modules with meaningful, consistent names
3. Reference dependent modules' outputs properly

Example:

```bicep
module roleAssignment 'modules/role-assignment.bicep' = if (shouldAssignKeyVaultRoles) {
  name: '${deployment().name}-ra0'
  params: {
    keyVaultName: sseKeyVaultName
    sseUserAssignedIdentityName: sseIdentityName
  }
}

module iotOpsInstance 'modules/iot-ops-instance.bicep' = {
  name: '${deployment().name}-ioi1'
  params: {
    aioDataFlowInstanceConfig: aioDataFlowInstanceConfig
    aioExtensionConfig: aioExtensionConfig
    aioInstanceName: aioInstanceName
    aioMqBrokerConfig: aioMqBrokerConfig
    aioPlatformExtensionId: iotOpsInit.outputs.aioPlatformExtensionId
    arcConnectedClusterName: arcConnectedClusterName
    // ... additional parameters ...
  }
}
```

### Outputs Conventions

- ALWAYS provide helpful descriptions with `@description()`
- ALWAYS use conditional expressions for outputs that depend on conditional resources
- ALWAYS ensure outputs match the expected format for consumer modules

Example:

```bicep
@description('The ID of the Azure IoT Operations Platform Extension.')
output aioPlatformExtensionId string = aioPlatformExtension.id

@description('The ID of the Secret Store Extension.')
output secretStoreExtensionId string = secretStoreExtension.id

@description('The ID of the deployed Azure IoT Operations MQ Broker instance.')
output aioMqBrokerId string = shouldDeployResourceSyncRules ? mqBroker.id : ''
```

### Resource Naming Conventions

- ALWAYS use Azure resource naming conventions
- ALWAYS follow this pattern: `<resource-abbreviation>-${common.resourcePrefix}-${common.environment}-${common.instance}`
- Examples:
  - `id-${common.resourcePrefix}-arc-${common.environment}-${common.instance}` for User Assigned Identity
  - `kv-${common.resourcePrefix}-${common.environment}-${common.instance}` for Key Vault

## Bicep DOs and DON'Ts

### DO

- DO use the `@export()` decorator for types that will be used across modules
- DO use the `@description()` decorator for all types, parameters, and outputs
- DO use nullable properties with `?` for optional values
- DO use the safe access operator `.?` when accessing potentially null properties
- DO create default objects with default values for complex types
- DO use conditional deployments with `if` statements for optional resources
- DO use `${deployment().name}` prefix for module names and acronym followed by order number for uniqueness
- DO use section headers with `/*` comments to organize your code
- DO include comments for important logic or implementation details
- DO validate inputs when appropriate, especially for security-sensitive parameters
- DO use `Name` parameters instead of `Id` parameters for referencing existing resources

### DON'T

- DON'T use hardcoded values for resource names, locations, etc.
- DON'T reference resources by ID strings when you can use symbolic references
- DON'T create overly complex parameter structures without proper defaults
- DON'T use the `latest` API version for resources - always specify a specific version
- DON'T reference modules in ways that violate the module relationship rules
- DON'T omit metadata or descriptions for parameters, types, and outputs
- DON'T create circular dependencies between modules
- DON'T duplicate type definitions across modules - use imports instead

## Pre-Implementation Checklist

Before making ANY changes to Bicep code, ask yourself:

- [ ] Am I working on a Component Module, an Internal Module, or a Blueprint?
  - Component Module: Located directly under `src/000-grouping/000-component/bicep/`
  - Internal Module: Located under `src/000-grouping/000-component/bicep/modules/module-name.bicep`
  - Blueprint: Located under `blueprints/blueprint-name/bicep/`
- [ ] Am I following the correct file structure for this module type?
- [ ] Will my module references follow the module relationship rules?
- [ ] Are my parameters organized with appropriate groupings?
- [ ] Does my module use the correct naming conventions?
- [ ] Have I defined all required types in their appropriate files?
- [ ] Am I using the Common type correctly for resource naming and location?
- [ ] Are my dependencies correctly ordered to prevent deployment failures?

## Post-Implementation Checklist

After completing ALL changes, verify:

- [ ] Does every file have proper metadata (name, description)?
- [ ] Are all types properly defined with `@export()` and `@description()`?
- [ ] Are parameters properly organized with clear section headers?
- [ ] Are parameters properly sorted alphabetically within sections?
- [ ] Are resources using proper naming conventions with the Common type properties?
- [ ] Are all parameters properly documented with `@description()`?
- [ ] Are conditional resources properly implemented with `if` conditions?
- [ ] Are module references correct and following relationship rules?
- [ ] Are outputs properly documented and returning the expected values?
- [ ] Am I using specific API versions for all resources?
- [ ] Are there any circular dependencies between modules?
- [ ] Are complex types defined with proper defaults in the types.bicep file?
- [ ] Is commented code removed and documentation updated?
