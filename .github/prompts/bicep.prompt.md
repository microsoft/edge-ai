# Bicep IaC conventions

You are expert in Azure Bicep IaC conventions and best practices. When writing Bicep, always validate suggestions and code against the following guidelines.
You understand this project by looking at the [README.md](../../README.md), `CONTRIBUTING.md` and `coding conventions` files.
First look at `bicep conventions` for general Bicep coding standards.
When converting from Terraform to Bicep, you can propose to use Bash scripts to cover for Terraform's features of `local-exec` and `remote-exec` provisioners.
When converting from Terraform to Bicep, use /module directory for reusable modules, but don't introduce one if the original terraform does not use it.
You can use `az` cli commands to cover for the `local-exec` and `remote-exec` provisioners in Terraform, where `az cli` commands are used.
Use Bicep idiomatic syntax and features, such as `@description()` decorators, `@export()` decorators, and `@secure()` decorators.

## Source Components Structure Components and Modules (`/src`)

Component directory structure:

```plaintext
src/
  000-componentname/                   # Component with numerical prefix
    bicep/                         # Bicep implementation
      main.bicep                   # Main orchestration file
      types.bicep                  # Component-specific types with defaults
      types.core.bicep             # Core shared types (Common)
      modules/                     # Resource modules
        resources-name-a.bicep     # Individual modules
        resource-name-b.bicep      # Individual modules
    ci/
      bicep/
        main.bicep                 # CI wrapper for deployment
```

- Components use decimal naming for deployment order: `000-subscription`, `010-vm-host`
- Each component must include:
  - `/bicep` directory for implementation, `/bicep/modules` for reusable modules
  - `/ci/bicep` directory for CI/CD pipeline configuration wrappers

## Type system

Use a robust type system to improve project maintainability, the `Common` type system is used across all components, from file `types.core.bicep`:

```bicep
// In types.core.bicep
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

- Define complex types with defaults in `types.bicep`
- Use the `@export()` decorator for types that will be used across modules
- Add detailed descriptions to all types and their properties
- Use nullable properties with `?` when appropriate
- Always create default objects with default values for complex types
- For resources that require version tracking, use complex types
- Avoid creating custom object types for existing Azure resources - instead reference resources by name and use the `existing` keyword

Follow this type pattern to maintain consistent versioning across infrastructure:

```bicep
// In types.bicep

@export()
@description('The settings for the Azure IoT Operations Platform Extension.')
type AioPlatformExtension = {
  @description('The common settings for the extension.')
  release: Release

  settings: {
    @description('Whether or not to install managers for trust in the cluster.')
    installCertManager: bool?
  }
}

@export()
var aioPlatformExtensionDefaults = {
  release: {
    version: '0.7.6'
    train: 'preview'
  }
  settings: {
    installCertManager: true
  }
}
```

Implementation example:

```bicep
// In main.bicep
import * as types from './types.bicep'

@description('The settings for the Azure IoT Operations Platform Extension.')
param aioPlatformConfig types.AioPlatformExtension = types.aioPlatformExtensionDefaults
//...

resource aioPlatform 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = {
  scope: arcConnectedCluster
  name: 'azure-iot-operations-platform'
  properties: {
    extensionType: 'microsoft.iotoperations.platform'
    version: aioPlatformConfig.release.version
    releaseTrain: aioPlatformConfig.release.train
    autoUpgradeMinorVersion: false
  }
}
```

## Resource References

Always use the Bicep `existing` keyword to reference existing resources rather than passing resource IDs as strings:

```bicep
// Preferred approach
@description('The user assigned managed identity name.')
param userAssignedIdentityName string

// Reference existing resource
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: userAssignedIdentityName
}

// Access properties directly
var principalId = userAssignedIdentity.properties.principalId

// NOT recommended - passing IDs as strings
// param userAssignedIdentityId string  // Avoid this approach
```

- This approach validates that resources exist at deployment time
- It improves maintainability by requiring fewer parameters
- It makes dependencies between resources more explicit
- Access resource properties using dot notation (e.g., `resource.property`)
- Use the `scope` property when resources are in different resource groups

### Parameters

Parameter ordering: always put common and complex types at the top, followed by module parameters
Parameters are always sorted alphabetically within their sections
Group related parameters under commented section headers
Always add `@description()` to every parameter
Allow multiline descriptions to keep them readable
Use consistent naming: `resourceName`, `shouldCreateResource`, see for example [types.bicep](../../src/040-iot-ops/bicep/types.bicep)
Provide sensible defaults when appropriate
Parameter defaults should only be provided at the top level, not at the module
Parameters should be simple types, with or without defaults
Use string interpolation for naming resources that includes Common type properties
Use resourceGroup() function instead of passing resource group objects as parameters

Example for parameters and section headings in `main.bicep` files, which calls two modules (storage and schema registry):

```bicep
// In main.bicep
import * as core from './types.core.bicep'
import * as types from './types.bicep'

@description('The common component configuration.')
param common core.Common

/*
  Storage Account for Schema Registry Parameters
*/

@description('Whether or not to create a new Storage Account for the ADR Schema Registry.')
param shouldCreateStorageAccount bool = true

@description('The name for the Resource Group for the Storage Account.')
param storageAccountResourceGroupName string = resourceGroup().name

@description('The settings for the new Storage Account.')
param storageAccountSettings types.StorageAccountSettings = {
  replicationType: 'LRS'
  tier: 'Standard'
}

/*
  Schema Registry Parameters
*/

@description('The name for the ADR Schema Registry.')
param schemaRegistryName string = 'sr-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('''
The ADLS Gen2 namespace for the ADR Schema Registry.
This is an example of a multi-line description.
''')
param schemaRegistryNamespace string = 'srns-${common.resourcePrefix}-${common.environment}-${common.instance}'

```

## Modules

Each module imports necessary type definitions
Always include the `common` parameter
Use consistent output naming: `resourceNameId`, `resourceName`
Consistently pass the `common` parameter to all modules
Use conditional deployment when appropriate
Set appropriate `dependsOn` relationships

### Naming Conventions

Resource names use kebab-case: `'resource-name-with-hyphens'`
Use the safe access (.?) operator. For example `${common.?instance}`
Parameters use camelCase: `paramName`
Types use PascalCase: `CommonType`
Output names match resource names with descriptive suffixes: `resourceNameId`
Match outputs to module interfaces when used by dependent modules
Apply rfc2119 to all variable names when applicable

### Resources

Nest child resources under parent resource scope when possible
Use conditional deployment when appropriate

```bicep
// In main.bicep

resource parentResource 'Microsoft.ResourceType/parentResourceType@2024-01-01' = {
  name: 'parentResourceName'
  location: 'location'

  resource childResource 'childResourceType' = {
    name: 'childResourceName'
    properties: {
      // Child resource properties
    }
  }
}
```

### CI setup

Include a proper `ci/bicep/main.bicep` wrapper that creates necessary type definitions and passes parameters correctly to the main module
Imports the necessary type definitions
Defines all parameters that the main component expects
Simply wraps the main bicep component without creating test resources
CI bicep file acts as a thin wrapper for the component, it is not setting up test resources

```bicep
// In ci/bicep/main.bicep - as example
import * as core from '../../bicep/types.core.bicep'
import * as types from '../../bicep/types.bicep'

@description('The common component configuration.')
param common core.Common

/*
  Virtual Machine Parameters
*/

@description('The number of host VMs to create if a multi-node cluster is needed.')
param vmCount int = 2

@description('Size of the VM')
param vmSkuSize string = 'Standard_D8s_v3'

/*
  Modules
*/

module iotOpsCloudReqs '../../bicep/main.bicep' = {
  name: '${common.resourcePrefix}-iotOpsCloudReqs'
  params: {
    common: common
  }
}
```

## Comment sections in Bicep files

When writing Bicep files, use the following format for section headers:

```bicep
/*
  Section Name
*/
```

Key points:

- Use a single line comment start (/*) and end (*/)
- Include two spaces of indentation for the section name
- No asterisks (*) on each line
- Leave a blank line after the section header
- Use consistent capitalization for section names (Title Case)
- Common sections: Common Parameters, Resources, Variables, Modules, Outputs
- Group parameters logically under domain-specific section headers

## Blueprints Structure (`/blueprints`)

### Purpose and Conventions

- Blueprints combine multiple components from `/src` to create deployable solutions
- Use descriptive names reflecting their purpose (e.g. `full-single-cluster`)

Conventions:

- When generating a blueprint, always validate the referenced components in `/src` exist in Bicep
- Always put the blueprint in the `/blueprints` directory
- When generating README.md files for blueprints, always validate parameters are specific to the blueprint

## Critical Rules (Always Follow)

- ALWAYS alphabetically sort parameters, per header grouping, but do this in sections: common and complex types at the top, then module parameters
  ❌ BAD: Leaving new unordered
  ✓ GOOD: Reordering the complete variable list alphabetically

## Implementation Checklist

Before finalizing code changes, verify:

- [ ] Have all parameters been alphabetically sorted in ALL types files?
- [ ] Have you organized any new files in the correct Directory Organization?
- [ ] Have you ensured not to use `latest` API version? Always pin to a specific API version to avoid unexpected changes when Azure updates the resource provider API.
- [ ] Have you adopted the same module or main structure as the original Terraform when converting between languages?
- [ ] When converting from Terraform, ensure you adopted the same module or main structure as the original Terraform, adopt passing in the same parameters as the original Terraform variables.
