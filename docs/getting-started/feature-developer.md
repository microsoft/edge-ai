---
title: Feature Developer Guide - Getting Started
description: Comprehensive guide for contributors developing new features and components in the AI on Edge Flagship Accelerator, covering development environment, processes, and coding standards
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: how-to
estimated_reading_time: 10
keywords:
  - feature development
  - component development
  - developer guide
  - contribution
  - terraform
  - bicep
  - infrastructure as code
  - development environment
  - coding standards
  - testing
  - CI/CD
---

## Feature Developer Guide - Getting Started

This guide is for contributors who want to add new features, components, or improve existing functionality in the AI on Edge Flagship Accelerator. It provides comprehensive guidance on the development environment, processes, and standards.

## Repository Structure and Organization

### Understanding the Architecture

The repository follows a structured component-based architecture:

```text
edge-ai/
├── src/                           # Source components
│   ├── 000-cloud/                 # Cloud infrastructure components
│   │   ├── 010-security-identity/ # Identity and security
│   │   ├── 020-networking/        # Network infrastructure
│   │   └── 030-storage/           # Storage solutions
│   └── 100-edge/                  # Edge infrastructure components
│       ├── 110-iot-ops/           # IoT Operations
│       ├── 120-kubernetes/        # Kubernetes cluster
│       └── 130-monitoring/        # Monitoring and observability
├── blueprints/                    # Deployment templates
├── docs/                          # Documentation
├── scripts/                       # Automation scripts
└── tests/                         # Test suites
```

### Component Naming Convention

Components follow a decimal naming pattern for deployment order:

- **Grouping**: `{000}-{grouping_name}` (e.g., `000-cloud`, `100-edge`)
- **Components**: `{000}-{component_name}` (e.g., `010-security-identity`)
- **Frameworks**: Each component supports both `terraform/` and `bicep/` implementations

### Internal Modules

Components can contain internal modules:

- **Location**: `{component}/modules/{internal_module}`
- **Scope**: Internal modules are ONLY referenced from their parent component
- **Rule**: Never reference internal modules from outside the component

## Development Environment Setup

### Complete Dev Container Configuration

The Dev Container provides a fully configured development environment with all necessary tools and dependencies.

#### Initial Setup

1. **Prerequisites**:
   - Docker Desktop installed and running
   - Visual Studio Code with Dev Containers extension
   - Git configured with your credentials

2. **Clone and open repository**:

   ```bash
   git clone {{CLONE_URL}}
   cd edge-ai
   code .
   ```

3. **Launch Dev Container**:
   - When prompted, click "Reopen in Container"
   - Or use Command Palette: `Remote-Containers: Reopen in Container`

#### Git Configuration in Dev Container

Configure Git for development work:

```bash
# Set your identity
git config --global user.name "Your Name"
git config --global user.email "your.email@domain.com"

# Configure conventional commit template
git config --global commit.template .github/.gitmessage

# Set default branch
git config --global init.defaultBranch main

# Configure pull behavior
git config --global pull.rebase false
```

#### SSH Configuration

For SSH authentication with GitHub:

1. **Generate SSH key** (if you don't have one):

   ```bash
   ssh-keygen -t ed25519 -C "your.email@domain.com"
   ```

2. **Add to SSH agent**:

   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```

3. **Add public key to GitHub**: Copy `~/.ssh/id_ed25519.pub` to your GitHub SSH keys

### Project Configuration and Scripts

The project uses `package.json` for standardized development tasks:

#### Available npm Scripts

```bash
# Development and linting
npm install                    # Install dependencies
npm run lint                   # Run all linters
npm run lint-fix               # Fix common linting issues
npm run lint-devcontainer      # Run linters (Dev Container optimized)
npm run lint-fix-devcontainer  # Fix linters (Dev Container optimized)

# Markdown and documentation
npm run mdlint                 # Run markdown linting
npm run mdlint-fix             # Fix markdown issues
npm run cspell                 # Run spell check

# Security and compliance
npm run checkov-changes        # Security scan on changed folders
npm run checkov-all            # Security scan on all folders

# Language and link checking
npm run link-check             # Check for language-specific links
npm run link-fix               # Fix language-specific links
```

#### Linting and Code Quality Tools

The Dev Container includes comprehensive linting and quality tools:

1. **MegaLinter**: Comprehensive multi-language linting
   - Configuration: `.mega-linter.yml`
   - Runs automatically in CI/CD
   - Documentation: `docs/build-cicd/megalinter-template.md`

2. **Terraform Tools**:
   - `terraform fmt` - Code formatting
   - `terraform validate` - Configuration validation
   - `tflint` - Advanced Terraform linting
   - `checkov` - Security scanning

3. **Bicep Tools**:
   - `az bicep build` - Template compilation
   - `az bicep lint` - Template validation

4. **Markdown Tools**:
   - `markdownlint` - Markdown linting
   - `markdown-table-formatter` - Table formatting
   - `cspell` - Spell checking

5. **Security Tools**:
   - `checkov` - IaC security scanning
   - `gitleaks` - Secret detection
   - `grype` - Vulnerability scanning

#### Dev Container Maintenance

Keep your development environment updated:

```bash
# Update Dev Container
# Use Command Palette: "Remote-Containers: Rebuild Container"

# Update npm dependencies
npm update

# Update Azure CLI extensions
az extension update --name azure-iot

# Update Terraform providers
terraform init -upgrade
```

## Component Development Process

### Creating a New Component

#### Step 1: Planning

Before coding, define:

1. **Purpose**: What problem does this component solve?
2. **Grouping**: Does it belong in `000-cloud` or `100-edge`?
3. **Dependencies**: What other components does it depend on?
4. **Interfaces**: What inputs and outputs will it provide?

#### Step 2: Create Component Structure

1. **Create component directory**:

   ```bash
   # Choose appropriate grouping and number
   mkdir -p src/000-cloud/040-my-component/{terraform,bicep}
   cd src/000-cloud/040-my-component
   ```

2. **Create README.md**:

   ```bash
   # Document the component purpose and usage
   cat > README.md << 'EOF'
   # My Component

   ## Overview

   Brief description of what this component does.

   ## Dependencies

   - Component A (010-security-identity)
   - Component B (020-networking)

   ## Usage

   ### Terraform

   ```hcl
   module "my_component" {
     source = "./src/000-cloud/040-my-component/terraform"
     # parameters
   }
   ```

   ### Bicep

   ```bicep
   module myComponent './src/000-cloud/040-my-component/bicep/main.bicep' = {
     // parameters
   }
   ```

   EOF

   ```bash

#### Step 3: Implement Terraform Version

1. **Create main.tf**:

   ```hcl
   # src/000-cloud/040-my-component/terraform/main.tf

   terraform {
     required_version = ">= 1.0"
     required_providers {
       azurerm = {
         source  = "hashicorp/azurerm"
         version = "~> 3.0"
       }
     }
   }

   # Component implementation
   resource "azurerm_resource_group" "main" {
     name     = var.resource_group_name
     location = var.location

     tags = var.tags
   }
   ```

2. **Create variables.tf**:

   ```hcl
   # src/000-cloud/040-my-component/terraform/variables.tf

   variable "location" {
     description = "Azure region for resources"
     type        = string
   }

   variable "resource_group_name" {
     description = "Name of the resource group"
     type        = string
   }

   variable "tags" {
     description = "Tags to apply to resources"
     type        = map(string)
     default     = {}
   }
   ```

3. **Create outputs.tf**:

   ```hcl
   # src/000-cloud/040-my-component/terraform/outputs.tf

   output "resource_group_name" {
     description = "Name of the created resource group"
     value       = azurerm_resource_group.main.name
   }

   output "location" {
     description = "Azure region of the resource group"
     value       = azurerm_resource_group.main.location
   }
   ```

#### Step 4: Implement Bicep Version

1. **Create main.bicep**:

   ```bicep
   // src/000-cloud/040-my-component/bicep/main.bicep

   @description('Azure region for resources')
   param location string

   @description('Name of the resource group')
   param resourceGroupName string

   @description('Tags to apply to resources')
   param tags object = {}

   // Component implementation
   resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
     name: resourceGroupName
     location: location
     tags: tags
   }

   // Outputs
   output resourceGroupName string = resourceGroup.name
   output location string = resourceGroup.location
   ```

### Testing and Validation Requirements

#### Local Testing

Before committing, run comprehensive tests:

```bash
# Navigate to your component
cd src/000-cloud/040-my-component

# Test Terraform
cd terraform
terraform init
terraform validate
terraform fmt -check
terraform plan

# Test Bicep
cd ../bicep
az bicep build --file main.bicep
az bicep lint --file main.bicep

# Run repository-wide linting
cd ../../..
npm run lint-devcontainer
```

#### Creating Test Scripts

Create automated tests for your component:

```bash
# Create test directory
mkdir -p tests/components/040-my-component

# Create test script
cat > tests/components/040-my-component/test.sh << 'EOF'
#!/bin/bash
set -e

echo "Testing 040-my-component..."

# Test Terraform
cd src/000-cloud/040-my-component/terraform
terraform init
terraform validate
terraform fmt -check

# Test Bicep
cd ../bicep
az bicep build --file main.bicep

echo "Component tests passed!"
EOF

chmod +x tests/components/040-my-component/test.sh
```

#### Integration Testing

Test your component with dependent components:

```bash
# Create integration test blueprint
mkdir -p tests/integration/my-component-test/{terraform,bicep}

# Test component integration in a minimal blueprint
# This ensures your component works with others
```

## Pull Request Process and Coding Standards

### Conventional Commits

All commits must follow the conventional commit format:

#### Commit Structure

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### Commit Types

- **feat**: New feature or component
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring without functionality changes
- **test**: Adding or modifying tests
- **chore**: Build process or auxiliary tool changes
- **ci**: CI/CD configuration changes

#### Examples

```bash
# Adding a new component
git commit -m "feat(components): add storage component with Terraform and Bicep implementations"

# Fixing a bug
git commit -m "fix(networking): resolve subnet configuration issue in multi-node deployments"

# Documentation update
git commit -m "docs(components): add usage examples for identity component"

# Refactoring
git commit -m "refactor(terraform): standardize variable naming across components"
```

### Pull Request Workflow

#### Creating Feature Branches

```bash
# Create and switch to feature branch
git checkout -b feature/storage-component
git checkout -b fix/networking-subnet-issue
git checkout -b docs/component-examples
```

#### Pre-commit Validation

Before creating a PR, ensure quality:

```bash
# Run all linting and validation
npm run lint-devcontainer

# Run component-specific tests
./tests/components/040-my-component/test.sh

# Check conventional commit format
git log --oneline -5  # Verify recent commits follow format
```

#### Creating Pull Requests

1. **Using GitHub CLI**:

   ```bash
   # Create PR with conventional commit title
   gh pr create \
     --title "feat(components): add storage component with dual implementation" \
     --body "Adds new storage component with Terraform and Bicep implementations"
   ```

2. **Using GitHub Copilot PR Prompt**:
   - Use `/pull-request` in Copilot Chat
   - Automatically generates PR title and description
   - Follows conventional commit format
   - Includes security and compliance analysis

#### PR Requirements

Every PR must include:

1. **Clear description** of changes and motivation
2. **Conventional commit format** in PR title
3. **Documentation updates** if adding new features
4. **Test coverage** for new components
5. **Linting compliance** (no failures)
6. **Security scan** results (if applicable)

### Project-Specific GitHub Copilot Prompts

#### Task Planning and Implementation

1. **Task Planner** (`/task-planner`):
   - Creates structured plan files in `.copilot-tracking/plans/`
   - Breaks down complex features into phases
   - Maintains notes files for tracking progress

2. **Task Implementer** (`/task-implementer`):
   - Implements tasks according to plan files
   - Updates progress tracking
   - Follows structured implementation approach

#### Using Task Prompts

```bash
# Start a new feature development
# 1. Use /task-planner in Copilot Chat
# 2. Describe your feature requirements
# 3. Review generated plan file
# 4. Use /task-implementer to execute the plan
```

### Code Quality Standards

#### Terraform Standards

1. **Formatting**: Use `terraform fmt` consistently
2. **Variables**: Include descriptions and appropriate types
3. **Outputs**: Document all outputs with descriptions
4. **Providers**: Pin provider versions using `~>` constraints
5. **Documentation**: Use Terraform-docs for automated documentation

#### Bicep Standards

1. **Parameters**: Use appropriate decorators (@description, @allowed)
2. **Resources**: Use latest stable API versions
3. **Modules**: Prefer modules over individual resources
4. **Outputs**: Clearly document output purposes
5. **Validation**: Use parameter validation where appropriate

#### Documentation Standards

1. **README files**: Every component needs comprehensive documentation
2. **Code comments**: Explain complex logic and decisions
3. **Examples**: Provide realistic usage examples
4. **MkDocs compliance**: Follow repository documentation standards

## Debugging and Troubleshooting

### Common Development Issues

#### Terraform Issues

1. **State conflicts**:

   ```bash
   # Refresh state
   terraform refresh

   # Import existing resources
   terraform import azurerm_resource_group.main /subscriptions/.../resourceGroups/name
   ```

2. **Provider version conflicts**:

   ```bash
   # Upgrade providers
   terraform init -upgrade

   # Lock provider versions
   terraform providers lock
   ```

#### Bicep Issues

1. **Template compilation errors**:

   ```bash
   # Build with verbose output
   az bicep build --file main.bicep --verbose

   # Lint for best practices
   az bicep lint --file main.bicep
   ```

2. **Parameter validation**:

   ```bash
   # Test parameter files
   az deployment group validate \
     --resource-group test \
     --template-file main.bicep \
     --parameters @parameters.json
   ```

#### Dev Container Issues

1. **Container rebuild**:

   ```bash
   # Rebuild container completely
   # Command Palette: "Remote-Containers: Rebuild Container"
   ```

2. **Docker issues**:

   ```bash
   # Clean Docker system
   docker system prune -a

   # Restart Docker Desktop
   ```

### Getting Help

1. **GitHub Copilot**: Ask specific questions about errors and code
2. **Repository issues**: Create issues with detailed error information
3. **Documentation**: Check component README files and docs/
4. **Community**: Engage with other contributors for guidance

## Advanced Development Topics

### Dependency Management and Versioning

Components use semantic versioning principles:

- **Major**: Breaking changes to interfaces
- **Minor**: New features, backward compatible
- **Patch**: Bug fixes, no interface changes

### Component Interface Design

Design consistent interfaces across Terraform and Bicep:

1. **Input parameters**: Use same names and types
2. **Output values**: Provide equivalent outputs
3. **Resource naming**: Follow consistent patterns
4. **Tagging**: Support standard tagging strategies

### Security Considerations

1. **Least privilege**: Grant minimal required permissions
2. **Managed identities**: Use Azure managed identities where possible
3. **Secrets management**: Never hard-code secrets
4. **Network security**: Implement proper network isolation
5. **Compliance**: Follow organizational security policies

## Next Steps

After contributing your first component:

1. **Monitor usage**: See how your component is used in blueprints
2. **Gather feedback**: Listen to user experiences and suggestions
3. **Iterate and improve**: Make enhancements based on real-world usage
4. **Mentor others**: Help new contributors with similar tasks
5. **Expand expertise**: Learn about other areas of the platform

## Additional Resources

- **[Blueprint Developer Guide](blueprint-developer.md)** - Create deployment scenarios
- **[Coding Conventions](../coding-conventions.md)** - Detailed coding standards
- **[AI-Assisted Engineering](../ai-assisted-engineering.md)** - Using GitHub Copilot effectively
- **[Terraform Documentation][terraform-docs]** - Official Terraform guides
- **[Bicep Documentation][bicep-docs]** - Official Bicep guides
- **[Azure IoT Operations Documentation][iot-ops-docs]** - Platform documentation

---

*This guide is part of the AI on Edge Flagship Accelerator project. For the latest updates and comprehensive resources, visit our [project repository][project-repo].*

[terraform-docs]: https://www.terraform.io/docs
[bicep-docs]: https://docs.microsoft.com/azure/azure-resource-manager/bicep/
[iot-ops-docs]: https://learn.microsoft.com/azure/iot-operations/
[project-repo]: {{REPO_URL}}

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
