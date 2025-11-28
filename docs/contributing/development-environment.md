---
title: Development Environment Setup
description: Comprehensive guide for setting up your development environment using Dev Container with Visual Studio Code, including prerequisites, installation steps, and tool configurations
author: Edge AI Team
ms.date: 2025-06-06
ms.topic: how-to
estimated_reading_time: 6
keywords:
  - development environment
  - dev container
  - visual studio code
  - docker
  - setup guide
  - prerequisites
  - tools
  - configuration
---

## Development Environment Setup

This guide provides comprehensive instructions for setting up a consistent development environment for the AI on Edge Flagship Accelerator. The recommended approach uses Visual Studio Code with Dev Containers to ensure all contributors work with the same tools and configurations.

## Prerequisites

Before setting up your development environment, ensure you have:

- **Docker Desktop** installed and running
- **Visual Studio Code** with the Dev Containers extension
- **Git** configured with your credentials
- **GitHub account** with appropriate repository access

## Dev Container Setup

The Dev Container provides a pre-configured development environment with all necessary tools, dependencies, and configurations.

### Initial Setup

1. **Clone the repository**:

   ```bash
   git clone {{CLONE_URL}}
   cd edge-ai
   ```

2. **Open in Visual Studio Code**:

   ```bash
   code .
   ```

3. **Reopen in Dev Container**:
   - When prompted by VS Code, click "Reopen in Container"
   - Or use Command Palette: `Remote-Containers: Reopen in Container`
   - Wait for the container to build and start (first time may take several minutes)

4. **Verify installation**:

   ```bash
   # Check that required tools are available
   terraform version
   az version
   kubectl version --client
   npm --version
   python3 --version
   ```

### Git Configuration

The Dev Container should copy your Git configuration from your host machine, but you may need to configure it manually:

```bash
# Set your Git identity
git config --global user.name "Your Name"
git config --global user.email "your.email@address"

# Verify configuration
git config --list
```

### SSH Configuration

For SSH to work with your local SSH keys in the Dev Container, configure an SSH agent following [VS Code's instructions](https://code.visualstudio.com/docs/remote/containers#_sharing-git-credentials-with-your-container).

**Important for Windows users**: If you're running Windows and launch VS Code from the start menu or PowerShell, use the Windows SSH agent instructions (even if using WSL/WSL2).

## Project Configuration

### npm Scripts

The project uses `package.json` to define development scripts that provide consistent command execution across environments:

```bash
# Install project dependencies
npm install

# Development and testing commands
npm run lint                    # Run all linters
npm run lint-fix               # Fix common linting issues
npm run lint-devcontainer      # Run linters in Dev Container mode
npm run lint-fix-devcontainer  # Fix linting issues in Dev Container mode

# Markdown-specific commands
npm run mdlint                 # Run markdown linting
npm run mdlint-fix             # Fix markdown linting issues

# Spell checking
npm run cspell                 # Run spell checker

# Security scanning
npm run checkov-changes        # Scan changed folders only
npm run checkov-all           # Scan all folders

# Link validation
npm run link-check            # Check for language-specific links
npm run link-fix              # Fix language-specific links
```

## Development Tools

### Linting and Code Quality

The Dev Container includes pre-configured linting tools for maintaining code quality:

#### MegaLinter

Run comprehensive linting across all file types:

```bash
# Run all configured linters
npm run lint-devcontainer

# Fix automatically fixable issues
npm run lint-fix-devcontainer
```

For detailed information about the MegaLinter configuration, see the [MegaLinter documentation](../../.azdo/templates/megalinter-template.md).

#### Markdown Linting

Ensure documentation meets quality standards:

```bash
# Check markdown files
npm run mdlint

# Auto-fix markdown issues
npm run mdlint-fix
```

**Note**: Not all markdown errors are automatically fixable. Review and fix remaining issues manually.

#### Spell Checking

Maintain professional documentation standards:

```bash
# Run spell checker
npm run cspell
```

If cspell detects unknown words that should be ignored:

- Add the word to `cspell-cse.txt` for project-specific terms
- For common computing terms, consider contributing to the [cspell software terms dictionary](https://github.com/streetsidesoftware/cspell-dicts/tree/main/dictionaries/software-terms/src)

### Security Scanning

The project integrates Checkov for infrastructure-as-code security analysis:

```bash
# Scan only changed folders
npm run checkov-changes

# Scan entire repository
npm run checkov-all
```

The scanning process:

1. Detects folders with changes (or scans all with the all flag)
2. Runs Checkov security scanner on identified folders
3. Generates a JUnit XML report at `./checkov-results/code-analysis.xml`

### Infrastructure as Code Tools

#### Terraform

The Dev Container includes:

- **Terraform CLI** for infrastructure provisioning
- **TFLint** for Terraform code analysis
- **terraform-docs** for automatic documentation generation

```bash
# Verify Terraform setup
terraform version

# Initialize a Terraform directory
terraform init

# Plan infrastructure changes
terraform plan

# Apply infrastructure changes
terraform apply
```

#### Bicep

The Dev Container includes:

- **Bicep CLI** for Azure Resource Manager template development
- **Bicep linter** for code quality validation

```bash
# Verify Bicep setup
az bicep version

# Build Bicep files
az bicep build --file main.bicep

# Validate Bicep templates
az bicep validate --file main.bicep
```

#### Azure CLI

Pre-configured for Azure resource management:

```bash
# Verify Azure CLI
az version

# Login to Azure (interactive)
az login

# Set subscription
az account set --subscription "your-subscription-id"
```

#### Kubernetes Tools

The Dev Container includes kubectl and Helm for Kubernetes management:

```bash
# Verify kubectl
kubectl version --client

# Verify Helm
helm version

# Connect to a cluster
kubectl config use-context your-cluster-context
```

## Development Workflow

### Branch Management

1. **Create feature branches** from the main branch:

   ```bash
   git checkout main
   git pull origin main
   git checkout -b feat/your-feature-name
   ```

2. **Make changes** using the development tools and scripts
3. **Test changes** using the provided npm scripts
4. **Commit changes** following [conventional commit guidelines](./coding-conventions.md#conventional-commits)
5. **Push and create pull requests** using the [PR guidelines](./contributing.md#pull-request-process)

### Code Quality Workflow

Before committing changes:

```bash
# Run comprehensive linting
npm run lint-devcontainer

# Fix automatically fixable issues
npm run lint-fix-devcontainer

# Run security scanning on changes
npm run checkov-changes

# Verify spell checking
npm run cspell
```

### Testing Workflow

For infrastructure components:

```bash
# Navigate to component directory
cd src/000-cloud/010-security-identity/terraform

# Initialize and validate
terraform init
terraform validate
terraform plan

# Run component tests
cd ../tests
go test -v
```

## GitHub Copilot Integration

The development environment is optimized for GitHub Copilot assistance:

### Custom Instructions

The project includes comprehensive [GitHub Copilot instructions](../../.github/copilot-instructions.md) that:

- Automatically apply project conventions
- Provide context-aware prompt file discovery
- Ensure consistent code formatting and structure

### Reusable Prompts

Access specialized prompts via the Command Palette or chat:

- **Pull Request Generation**: `/pull-request` - Generate comprehensive PR descriptions
- **Task Planning**: `/task-planner` - Create structured implementation plans
- **Task Implementation**: `/task-implementer` - Execute plans with progress tracking

For detailed information, see the [AI-Assisted Engineering guide](./ai-assisted-engineering.md).

## Troubleshooting

### Common Issues

#### Container Build Failures

If the Dev Container fails to build:

1. Ensure Docker Desktop is running
2. Check available disk space (containers require significant space)
3. Try rebuilding: Command Palette → `Remote-Containers: Rebuild Container`

#### Git Authentication Issues

If Git operations fail:

1. Verify SSH agent configuration
2. Check SSH key access to GitHub
3. Use HTTPS with personal access tokens if SSH fails

#### Tool Version Mismatches

If tools report unexpected versions:

1. Rebuild the Dev Container to get latest tool versions
2. Check `.devcontainer/devcontainer.json` for version specifications
3. Update the container configuration if needed

### Getting Help

For development environment issues:

1. Check the [troubleshooting documentation](./troubleshooting.md)
2. Review existing [GitHub issues]({{ISSUES_URL}})
3. Create a new issue with detailed environment information

## Maintenance

### Container Updates

Periodically update the Dev Container:

```bash
# Rebuild container with latest updates
# Command Palette → Remote-Containers: Rebuild Container
```

### Dependency Updates

Keep project dependencies current:

```bash
# Update npm dependencies
npm update

# Update container base images (requires container rebuild)
```

## Alternative Setup (Manual)

If you cannot use Dev Containers, manually install these tools:

- **Terraform** >= 1.0
- **Azure CLI** >= 2.0
- **Bicep CLI** (via Azure CLI)
- **kubectl** >= 1.20
- **Helm** >= 3.0
- **Node.js** >= 16 (for npm scripts)
- **Python** >= 3.8
- **Docker** (for container operations)

**Note**: Manual setup may result in tool version differences and inconsistent behavior. The Dev Container approach is strongly recommended for contributors.

## Next Steps

With your development environment configured:

1. Review the [Contributing Guidelines](./contributing.md)
2. Understand the [Coding Conventions](./coding-conventions.md)
3. Explore [AI-Assisted Engineering](./ai-assisted-engineering.md) workflows
4. Choose a [Getting Started guide](../getting-started/README.md) based on your role

*🤖 Crafted with precision by ✨Copilot following brilliant human instruction, then carefully refined by our team of discerning human reviewers.*
