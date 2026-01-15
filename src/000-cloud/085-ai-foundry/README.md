---
title: Microsoft Foundry Component
description: Microsoft Foundry infrastructure with accounts, projects, and model deployments for AI development and deployment scenarios
author: Edge AI Team
ms.date: 2025-12-05
ms.topic: reference
keywords:
  - microsoft foundry
  - ai services
  - model deployments
  - cognitive services
  - ai projects
  - terraform
estimated_reading_time: 4
---

## Microsoft Foundry Component

This component creates Microsoft Foundry infrastructure for AI development and deployment scenarios. It provides Microsoft Foundry accounts (using the modern AIServices kind with project management), projects for organizing AI workloads, and configurable model deployments for OpenAI models.

## Purpose and Role

The Microsoft Foundry component enables AI developers and engineers to:

- **AI Foundation**: Create Microsoft Foundry accounts with project management capabilities using the modern AIServices pattern
- **Project Organization**: Organize AI workloads into separate projects with dedicated resources and configurations
- **Model Deployments**: Deploy and manage OpenAI models (GPT-4o, embeddings, etc.) with configurable scaling
- **Network Security**: Optional private endpoint connectivity with DNS zone integration
- **Responsible AI**: Configure content filtering policies for model deployments

## Component Resources

This component creates the following Azure resources:

### Core Infrastructure

- **Microsoft Foundry Account**: CognitiveServices account with kind="AIServices" and allowProjectManagement=true for modern AI workloads
- **Microsoft Foundry Projects** (Optional): Child resources for organizing AI workloads with dedicated configurations
- **Model Deployments** (Optional): OpenAI model deployments with configurable scaling and versioning

### Network Resources

- **Private Endpoint** (Optional): Secure private connectivity to Microsoft Foundry account with DNS zone integration

### Responsible AI Resources

- **RAI Policies** (Optional): Content filtering policies for model deployments

### Integration Dependencies

This component integrates with existing cloud infrastructure:

- **Resource Group**: Required for resource organization and management
- **Key Vault** (Optional): Customer-managed key encryption for enhanced security
- **Virtual Network** (Optional): Private endpoint subnet for secure network access

## Configuration Options

### Account Configuration

- **SKU**: S0 (required for AIServices kind)
- **Public Network Access**: Configurable public or private-only access
- **Local Authentication**: Optional API key authentication (can disable for Entra ID-only)
- **CMK Encryption**: Optional customer-managed key encryption using Key Vault

### Project Configuration

- **Multiple Projects**: Support for multiple projects via map variable
- **Project SKU**: Configurable SKU per project (default: S0)
- **Display Name**: Human-readable project names
- **Description**: Project descriptions for documentation

### Model Deployment Configuration

- **OpenAI Models**: Support for GPT-4o, text-embedding, and other OpenAI models
- **Scaling Options**: GlobalStandard, Standard, and other scale types
- **Capacity Configuration**: Configurable tokens-per-minute capacity
- **Version Management**: Model versioning with automatic upgrade options
- **RAI Policies**: Reference custom content filtering policies

### Private Endpoint Configuration

- **Optional Deployment**: Private endpoint creation can be disabled for public-access scenarios
- **DNS Zone Integration**: Supports multiple DNS zones for full functionality:
  - `privatelink.cognitiveservices.azure.com`
  - `privatelink.openai.azure.com`
  - `privatelink.services.ai.azure.com`

## Integration with Other Components

This component depends on and integrates with:

- **000-resource-group**: Resource organization and management (required)
- **010-security-identity** (Optional): Key Vault for customer-managed key encryption
- **050-networking** (Optional): VNet and subnet for private endpoint configuration

## Security Considerations

- **Managed Identity**: System-assigned identity for secure Azure resource access
- **Network Isolation**: Optional private endpoint for secure network access
- **CMK Encryption**: Customer-managed keys stored in Key Vault for data encryption
- **Local Auth Control**: Option to disable API keys for Entra ID-only authentication
- **Responsible AI**: Content filtering policies for model deployments

## Deployment Options

### Bicep

The Bicep implementation provides feature parity with Terraform using native Azure Resource Manager deployment templates.

#### Directory Structure

```plaintext
src/000-cloud/085-ai-foundry/bicep/
├── main.bicep           # Main component orchestration
├── types.core.bicep     # Common type definitions
└── types.bicep          # Microsoft Foundry-specific types
```

#### Key Features

- **Native Bicep Resources**: Uses `Microsoft.CognitiveServices/accounts@2025-06-01` for Microsoft Foundry accounts
- **Type-Safe Parameters**: Exported types for configuration validation
- **Sequential Deployments**: `@batchSize(1)` decorator for model deployments respecting capacity limits
- **Optional Child Resources**: Projects, RAI policies, and model deployments via typed arrays
- **Private Endpoint Support**: Three DNS zones (cognitiveservices, openai, services.ai) with automatic A record creation

#### Type Definitions

The component exports the following types in `types.bicep`:

- **AiFoundryConfig**: Account configuration (SKU, network access, authentication)
- **AiProject**: Project definition with name, display name, and description
- **ModelDeployment**: Model deployment with format, name, version, and scaling configuration
- **RaiPolicy**: Responsible AI policy with content filters
- **ContentFilter**: Content filter configuration for RAI policies

#### Basic Deployment

Account-only deployment using common parameters:

```bicep
module aiFoundry '../../../src/000-cloud/085-ai-foundry/bicep/main.bicep' = {
  name: 'aiFoundry'
  scope: resourceGroup(resourceGroupName)
  params: {
    common: {
      resourcePrefix: 'myapp'
      location: 'eastus2'
      environment: 'dev'
      instance: '001'
    }
  }
}
```

#### Full Infrastructure Deployment

Complete setup with projects and model deployments:

```bicep
module aiFoundry '../../../src/000-cloud/085-ai-foundry/bicep/main.bicep' = {
  name: 'aiFoundry'
  scope: resourceGroup(resourceGroupName)
  params: {
    common: {
      resourcePrefix: 'myapp'
      location: 'eastus2'
      environment: 'dev'
      instance: '001'
    }
    aiFoundryConfig: {
      sku: 'S0'
      shouldEnablePublicNetworkAccess: true
      shouldEnableLocalAuth: true
    }
    aiProjects: [
      {
        name: 'aio-sidekick'
        displayName: 'AIO Sidekick Project'
        description: 'AI project for AIO Sidekick development'
      }
    ]
    modelDeployments: [
      {
        name: 'gpt-4o'
        model: {
          format: 'OpenAI'
          name: 'gpt-4o'
          version: '2024-11-20'
        }
        scale: {
          type: 'GlobalStandard'
          capacity: 10
        }
      }
    ]
  }
}
```

#### Private Endpoint Configuration Example

Secure deployment with private network access and DNS zone integration:

```bicep
module aiFoundry '../../../src/000-cloud/085-ai-foundry/bicep/main.bicep' = {
  name: 'aiFoundry'
  scope: resourceGroup(resourceGroupName)
  params: {
    common: {
      resourcePrefix: 'myapp'
      location: 'eastus2'
      environment: 'prod'
      instance: '001'
    }
    aiFoundryConfig: {
      sku: 'S0'
      shouldEnablePublicNetworkAccess: false
      shouldEnableLocalAuth: false
    }
    shouldCreatePrivateEndpoint: true
    privateEndpointSubnetId: networkingOutputs.subnetId
    virtualNetworkId: networkingOutputs.virtualNetworkId
  }
}
```

#### RAI Policy Configuration

Configure content filtering for responsible AI:

```bicep
module aiFoundry '../../../src/000-cloud/085-ai-foundry/bicep/main.bicep' = {
  name: 'aiFoundry'
  scope: resourceGroup(resourceGroupName)
  params: {
    common: commonConfig
    raiPolicies: [
      {
        name: 'strict-policy'
        basePolicyName: 'Microsoft.Default'
        mode: 'Blocking'
        contentFilters: [
          {
            name: 'Hate'
            enabled: true
            blocking: true
            severityThreshold: 'Low'
            source: 'Prompt'
          }
        ]
      }
    ]
    modelDeployments: [
      {
        name: 'gpt-4o'
        model: { format: 'OpenAI', name: 'gpt-4o', version: '2024-11-20' }
        scale: { type: 'GlobalStandard', capacity: 10 }
        raiPolicyName: 'strict-policy'
      }
    ]
  }
}
```

#### Private DNS Zones

When enabling private endpoints, three DNS zones are automatically created and configured:

| DNS Zone                                  | Purpose                |
|-------------------------------------------|------------------------|
| `privatelink.cognitiveservices.azure.com` | Cognitive Services API |
| `privatelink.openai.azure.com`            | OpenAI API endpoints   |
| `privatelink.services.ai.azure.com`       | AI Services endpoints  |

#### Blueprint Integration

The component is integrated into the full-single-node-cluster and full-multi-node-cluster blueprints with conditional deployment:

```bicep
param shouldDeployAiFoundry bool = false
param aiFoundryConfig core.AiFoundryConfig = core.aiFoundryConfigDefaults

module cloudAiFoundry '../../../src/000-cloud/085-ai-foundry/bicep/main.bicep' = if (shouldDeployAiFoundry) {
  name: '${deployment().name}-caf8'
  scope: resourceGroup(resourceGroupName)
  params: {
    common: common
    aiFoundryConfig: aiFoundryConfig
    aiProjects: aiFoundryProjects
    raiPolicies: aiFoundryRaiPolicies
    modelDeployments: aiFoundryModelDeployments
    shouldCreatePrivateEndpoint: shouldCreateAiFoundryPrivateEndpoint
    privateEndpointSubnetId: shouldCreateAiFoundryPrivateEndpoint ? cloudNetworking.outputs.subnetId : ''
    virtualNetworkId: shouldCreateAiFoundryPrivateEndpoint ? cloudNetworking.outputs.virtualNetworkId : ''
  }
}
```

### Terraform

Refer to [Terraform Components - Getting Started](../README.md#terraform-components---getting-started) for deployment instructions.

#### Deployment Scenarios

##### Account-Only Deployment

Suitable for scenarios where projects and models are managed externally:

```hcl
module "ai_foundry" {
  source = "../../src/000-cloud/085-ai-foundry/terraform"

  resource_prefix = "myapp"
  environment     = "dev"
  location        = "eastus2"
  instance        = "001"
  resource_group  = data.azurerm_resource_group.main
}
```

##### Full AI Infrastructure

Complete setup with projects and model deployments:

```hcl
module "ai_foundry" {
  source = "../../src/000-cloud/085-ai-foundry/terraform"

  resource_prefix = "myapp"
  environment     = "dev"
  location        = "eastus2"
  instance        = "001"
  resource_group  = data.azurerm_resource_group.main

  ai_projects = {
    sidekick = {
      name         = "aio-sidekick"
      display_name = "AIO Sidekick Project"
      description  = "AI project for AIO Sidekick development"
    }
  }

  model_deployments = {
    gpt4o = {
      name = "gpt-4o"
      model = {
        format  = "OpenAI"
        name    = "gpt-4o"
        version = "2024-11-20"
      }
      scale = {
        type     = "GlobalStandard"
        capacity = 10
      }
    }
  }
}
```

##### Private Endpoint Deployment

Secure deployment with private network access:

```hcl
module "ai_foundry" {
  source = "../../src/000-cloud/085-ai-foundry/terraform"

  resource_prefix = "myapp"
  environment     = "prod"
  location        = "eastus2"
  instance        = "001"
  resource_group  = data.azurerm_resource_group.main

  should_enable_public_network_access = false
  should_enable_private_endpoint      = true
  private_endpoint_subnet_id          = data.azurerm_subnet.private_endpoints.id
  private_dns_zone_ids = [
    data.azurerm_private_dns_zone.cognitive.id,
    data.azurerm_private_dns_zone.openai.id,
    data.azurerm_private_dns_zone.ai_services.id
  ]
}
```

#### Variables

##### Core Variables

| Variable          | Type     | Default | Description                     |
|-------------------|----------|---------|---------------------------------|
| `resource_prefix` | `string` | -       | Prefix for all resources        |
| `environment`     | `string` | -       | Environment: dev, test, or prod |
| `location`        | `string` | -       | Azure region for deployment     |
| `instance`        | `string` | `"001"` | Instance identifier             |

##### Dependency Variables

| Variable         | Type     | Description                             |
|------------------|----------|-----------------------------------------|
| `resource_group` | `object` | Resource group from 000-resource-group  |
| `key_vault`      | `object` | Key Vault for CMK encryption (optional) |

##### Configuration Variables

| Variable                              | Type          | Default | Description                                 |
|---------------------------------------|---------------|---------|---------------------------------------------|
| `ai_foundry_name`                     | `string`      | `null`  | Custom name (defaults to naming convention) |
| `sku`                                 | `string`      | `"S0"`  | SKU for AI Foundry account                  |
| `should_enable_public_network_access` | `bool`        | `true`  | Enable public network access                |
| `should_enable_local_auth`            | `bool`        | `true`  | Enable API key authentication               |
| `should_enable_cmk_encryption`        | `bool`        | `false` | Enable customer-managed key encryption      |
| `should_enable_private_endpoint`      | `bool`        | `false` | Create private endpoint                     |
| `ai_projects`                         | `map(object)` | `{}`    | Map of projects to create                   |
| `model_deployments`                   | `map(object)` | `{}`    | Map of model deployments                    |
| `rai_policies`                        | `map(object)` | `{}`    | Map of RAI content filtering policies       |
| `tags`                                | `map(string)` | `{}`    | Tags to apply to resources                  |

#### Outputs

##### Account Outputs

| Output                    | Description                                   |
|---------------------------|-----------------------------------------------|
| `ai_foundry`              | Complete Microsoft Foundry account object     |
| `ai_foundry_id`           | Microsoft Foundry account resource ID         |
| `ai_foundry_name`         | Microsoft Foundry account name                |
| `ai_foundry_endpoint`     | Microsoft Foundry account endpoint URL        |
| `ai_foundry_principal_id` | System-assigned managed identity principal ID |

##### Project and Deployment Outputs

| Output             | Description                                |
|--------------------|--------------------------------------------|
| `projects`         | Map of Microsoft Foundry project resources |
| `deployments`      | Map of model deployment resources          |
| `rai_policies`     | Map of RAI policy resources                |
| `private_endpoint` | Private endpoint resource (if created)     |

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

## External References

### Microsoft Foundry Documentation

- [Microsoft Foundry Overview](https://learn.microsoft.com/azure/ai-services/what-are-ai-services) - Complete platform overview and AI capabilities
- [Create Microsoft Foundry Resources with Terraform](https://learn.microsoft.com/azure/ai-foundry/how-to/create-resource-terraform) - Terraform deployment guide using AzAPI provider
- [Microsoft Foundry Projects](https://learn.microsoft.com/azure/ai-foundry/concepts/projects) - Project organization and management

### Model Deployment and Configuration

- [Azure OpenAI Model Deployment](https://learn.microsoft.com/azure/ai-services/openai/how-to/create-resource) - Model deployment options and scaling
- [Responsible AI Content Filtering](https://learn.microsoft.com/azure/ai-services/openai/concepts/content-filter) - Content filtering configuration

### Infrastructure Automation

- [AzAPI Provider Documentation](https://registry.terraform.io/providers/Azure/azapi/latest/docs) - AzAPI Terraform provider for Azure resources
- [Microsoft.CognitiveServices ARM Reference](https://learn.microsoft.com/azure/templates/microsoft.cognitiveservices/accounts) - ARM template reference for Cognitive Services

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
