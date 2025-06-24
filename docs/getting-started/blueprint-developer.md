---
title: Blueprint Developer Guide - Getting Started
description: Create custom deployment blueprints using existing components for edge AI solutions
author: Edge AI Team
ms.date: 2025-06-15
ms.topic: how-to
estimated_reading_time: 7
keywords:
  - blueprint developer
  - custom blueprints
  - terraform
  - bicep
  - components
  - edge AI architecture
---

## Blueprint Developer Guide - Getting Started

This guide is for developers who want to create custom deployment blueprints by combining existing components. Blueprints define complete deployment scenarios for specific use cases.

> **🎯 Master Blueprint Development:** Accelerate your learning with our [PraxisWorx Training Platform](/praxisworx/). Explore the [Edge-to-Cloud Systems Track](/praxisworx/training-labs/02-edge-to-cloud-systems/) for comprehensive training on AI-assisted composition of multi-component system architectures and blueprint creation.

## Understanding Blueprint Architecture

### What are Blueprints?

Blueprints are deployment templates that:

- **Combine multiple components** into cohesive solutions
- **Define infrastructure** for specific scenarios (single-node, multi-node, etc.)
- **Provide consistent interfaces** across Terraform and Bicep implementations
- **Include validation** and testing procedures

### Blueprint Structure

```text
blueprints/
├── {blueprint-name}/
│   ├── README.md                    # Blueprint documentation
│   ├── terraform/
│   │   ├── main.tf                  # Main Terraform configuration
│   │   ├── variables.tf             # Input parameters
│   │   ├── outputs.tf               # Output values
│   │   ├── terraform.tfvars.example # Example configuration
│   │   └── modules/                 # Local modules (if needed)
│   └── bicep/
│       ├── main.bicep               # Main Bicep template
│       ├── parameters.json          # Example parameters
│       └── modules/                 # Local modules (if needed)
```

### Component Integration

Blueprints reference components from the `src/` directory:

```text
src/
├── 000-cloud/
│   ├── 010-security-identity/       # Identity and security
│   ├── 020-networking/              # Network infrastructure
│   └── 030-storage/                 # Storage solutions
└── 100-edge/
    ├── 110-iot-ops/                 # IoT Operations
    ├── 120-kubernetes/              # Kubernetes cluster
    └── 130-monitoring/              # Monitoring and observability
```

## Development Environment Setup

### Dev Container Configuration

1. **Open the repository in VS Code**:

   ```bash
   git clone {{CLONE_URL}}
   cd edge-ai
   code .
   ```

2. **Reopen in Dev Container**:
   - Click "Reopen in Container" when prompted
   - Or use Command Palette: `Remote-Containers: Reopen in Container`

3. **Verify development tools**:

   ```bash
   # Infrastructure tools
   terraform version
   az version

   # Development tools
   git --version
   npm --version

   # Linting tools
   npm run lint --help
   ```

### Git Configuration

Configure Git for blueprint development:

```bash
# Set your identity
git config --global user.name "Your Name"
git config --global user.email "your.email@domain.com"

# Configure commit template for conventional commits
git config --global commit.template .github/.gitmessage

# Set up SSH (if using SSH authentication)
ssh-keygen -t ed25519 -C "your.email@domain.com"
```

## Creating a New Blueprint

### Step 1: Plan Your Blueprint

Before coding, define:

1. **Target scenario**: What problem does this blueprint solve?
2. **Required components**: Which components from `src/` do you need?
3. **Dependencies**: What order should components be deployed?
4. **Parameters**: What should be configurable by users?

### Step 2: Create Blueprint Structure

1. **Create blueprint directory**:

   ```bash
   mkdir -p blueprints/my-custom-blueprint/{terraform,bicep}
   cd blueprints/my-custom-blueprint
   ```

2. **Create README.md**:

   ```bash
   # Create from template
   cp ../full-single-node-cluster/README.md ./README.md
   # Edit to describe your blueprint
   code README.md
   ```

### Step 3: Implement Terraform Version

1. **Create main.tf**:

   ```hcl
   # blueprints/my-custom-blueprint/terraform/main.tf

   terraform {
     required_version = ">= 1.0"
     required_providers {
       azurerm = {
         source  = "hashicorp/azurerm"
         version = "~> 3.0"
       }
     }
   }

   provider "azurerm" {
     features {}
   }

   # Reference existing components
   module "identity" {
     source = "../../../src/000-cloud/010-security-identity/terraform"

     location            = var.location
     resource_group_name = var.resource_group_name
     environment         = var.environment
   }

   module "networking" {
     source = "../../../src/000-cloud/020-networking/terraform"

     location            = var.location
     resource_group_name = var.resource_group_name
     environment         = var.environment

     depends_on = [module.identity]
   }
   ```

2. **Create variables.tf**:

   ```hcl
   # blueprints/my-custom-blueprint/terraform/variables.tf

   variable "location" {
     description = "Azure region for resources"
     type        = string
     default     = "East US"
   }

   variable "resource_group_name" {
     description = "Name of the resource group"
     type        = string
   }

   variable "environment" {
     description = "Environment name (dev, test, prod)"
     type        = string
     default     = "dev"
   }
   ```

3. **Create outputs.tf**:

   ```hcl
   # blueprints/my-custom-blueprint/terraform/outputs.tf

   output "resource_group_name" {
     description = "Name of the created resource group"
     value       = var.resource_group_name
   }

   output "identity_principal_id" {
     description = "Principal ID of the managed identity"
     value       = module.identity.principal_id
   }
   ```

4. **Create terraform.tfvars.example**:

   ```hcl
   # blueprints/my-custom-blueprint/terraform/terraform.tfvars.example

   location            = "East US"
   resource_group_name = "rg-my-custom-blueprint"
   environment         = "dev"
   ```

### Step 4: Implement Bicep Version

1. **Create main.bicep**:

   ```bicep
   // blueprints/my-custom-blueprint/bicep/main.bicep

   @description('Azure region for resources')
   param location string = 'East US'

   @description('Name of the resource group')
   param resourceGroupName string

   @description('Environment name')
   @allowed(['dev', 'test', 'prod'])
   param environment string = 'dev'

   // Reference existing components
   module identity '../../../src/000-cloud/010-security-identity/bicep/main.bicep' = {
     name: 'identity-deployment'
     params: {
       location: location
       resourceGroupName: resourceGroupName
       environment: environment
     }
   }

   module networking '../../../src/000-cloud/020-networking/bicep/main.bicep' = {
     name: 'networking-deployment'
     params: {
       location: location
       resourceGroupName: resourceGroupName
       environment: environment
     }
     dependsOn: [identity]
   }

   // Outputs
   output resourceGroupName string = resourceGroupName
   output identityPrincipalId string = identity.outputs.principalId
   ```

2. **Create parameters.json**:

   ```json
   {
     "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
     "contentVersion": "1.0.0.0",
     "parameters": {
       "location": {
         "value": "East US"
       },
       "resourceGroupName": {
         "value": "rg-my-custom-blueprint"
       },
       "environment": {
         "value": "dev"
       }
     }
   }
   ```

## Testing and Validation

### Linting and Code Quality

Run validation tools before committing:

```bash
# Terraform validation
cd blueprints/my-custom-blueprint/terraform
terraform init
terraform validate
terraform fmt -check

# Bicep validation
cd ../bicep
az bicep build --file main.bicep

# Repository-wide linting
cd ../../..
npm run lint
```

### Local Testing

1. **Test Terraform deployment**:

   ```bash
   cd blueprints/my-custom-blueprint/terraform

   # Initialize
   terraform init

   # Plan (dry-run)
   terraform plan -var-file="terraform.tfvars.example"

   # Apply for testing
   terraform apply -var-file="terraform.tfvars.example"

   # Cleanup
   terraform destroy -var-file="terraform.tfvars.example"
   ```

2. **Test Bicep deployment**:

   ```bash
   cd blueprints/my-custom-blueprint/bicep

   # Create resource group
   az group create --name "rg-test-blueprint" --location "East US"

   # Deploy template
   az deployment group create \
     --resource-group "rg-test-blueprint" \
     --template-file main.bicep \
     --parameters @parameters.json

   # Cleanup
   az group delete --name "rg-test-blueprint" --yes
   ```

### Automated Testing

Create test scripts for CI/CD validation:

```bash
# Create test script
mkdir -p tests/blueprints/my-custom-blueprint
cat > tests/blueprints/my-custom-blueprint/test.sh << 'EOF'
#!/bin/bash
set -e

echo "Testing my-custom-blueprint..."

# Test Terraform
cd blueprints/my-custom-blueprint/terraform
terraform init
terraform validate
terraform plan -var-file="terraform.tfvars.example"

# Test Bicep
cd ../bicep
az bicep build --file main.bicep

echo "All tests passed!"
EOF

chmod +x tests/blueprints/my-custom-blueprint/test.sh
```

## Best Practices

### Blueprint Integration Best Practices

1. **Use component outputs as inputs**: Pass outputs from one component as inputs to another
2. **Respect dependencies**: Use `depends_on` (Terraform) or `dependsOn` (Bicep) for proper ordering
3. **Maintain consistency**: Ensure Terraform and Bicep implementations produce equivalent results
4. **Follow naming conventions**: Use consistent resource naming across components

### Documentation Standards

1. **Document parameters**: Clearly describe all input parameters
2. **Provide examples**: Include realistic example configurations
3. **Explain use cases**: Document when to use this blueprint
4. **Include diagrams**: Visual representations help users understand the architecture

### Security Considerations

1. **Principle of least privilege**: Grant minimal required permissions
2. **Use managed identities**: Avoid storing credentials in configurations
3. **Enable logging**: Include monitoring and audit capabilities
4. **Network security**: Implement proper network isolation and access controls

## GitHub Copilot for Blueprint Development

### Effective Prompts

Use these patterns when working with GitHub Copilot:

- **"Create a Terraform module that references the identity component from src/000-cloud/010-security-identity/"**
- **"Generate Bicep parameters for a multi-node Kubernetes deployment"**
- **"Help me debug this component dependency error in my blueprint"**
- **"Explain the outputs I need from the networking component for IoT Operations"**

### Project-Specific Prompts

Use repository-specific prompts for blueprint development:

1. **Pull Request Creation**: Use `/pull-request` in Copilot Chat for automated PR generation
2. **Task Planning**: Use `/task-planner` for complex blueprint development tasks
3. **Component Analysis**: Ask about specific components in the `src/` directory

## Conventional Commits and PR Process

### Commit Message Format

Follow conventional commit format for blueprint changes:

```text
feat(blueprints): add custom IoT edge deployment blueprint

- Combines identity, networking, and IoT Operations components
- Supports both single and multi-node configurations
- Includes comprehensive testing and validation
- Provides Terraform and Bicep implementations

Closes #123
```

### Pull Request Process

1. **Create feature branch**:

   ```bash
   git checkout -b feature/custom-iot-blueprint
   ```

2. **Make your changes** following the guidelines above

3. **Test thoroughly**:

   ```bash
   npm run lint
   ./tests/blueprints/my-custom-blueprint/test.sh
   ```

4. **Commit with conventional format**:

   ```bash
   git add .
   git commit -m "feat(blueprints): add custom IoT edge deployment blueprint"
   ```

5. **Create pull request** using the GitHub CLI or UI:

   ```bash
   gh pr create --title "feat(blueprints): add custom IoT edge deployment blueprint" --body "Description of changes"
   ```

6. **Use PR prompt** in GitHub Copilot for automated PR description generation

## Next Steps

After creating your blueprint:

1. **Update CI/CD**: Add your blueprint to automated testing pipelines
2. **Create documentation**: Write comprehensive usage guides
3. **Share with community**: Present your blueprint for review and feedback
4. **Iterate based on feedback**: Improve based on user testing and suggestions

## Additional Resources

- **[Feature Developer Guide](feature-developer.md)** - Contribute new components
- **[Component Documentation](src/README.md)** - Understanding existing components
- **[AI-Assisted Engineering](../contributing/ai-assisted-engineering.md)** - Using GitHub Copilot for blueprint development
- **[Terraform Best Practices][terraform-best-practices]** - Official Terraform guidelines
- **[Bicep Best Practices][bicep-best-practices]** - Official Bicep guidelines
- **[Azure IoT Operations Documentation][iot-ops-docs]** - Platform-specific guidance

---

*This guide is part of the AI on Edge Flagship Accelerator project. For the latest updates and comprehensive resources, visit our [project repository][project-repo].*

[terraform-best-practices]: https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html
[bicep-best-practices]: https://docs.microsoft.com/azure/azure-resource-manager/bicep/best-practices
[iot-ops-docs]: https://learn.microsoft.com/azure/iot-operations/
[project-repo]: {{REPO_URL}}

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
