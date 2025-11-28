---
title: Troubleshooting Guide
description: Common issues and solutions for development and deployment of the AI on Edge Flagship Accelerator, including environment setup, infrastructure deployment, and git workflow problems
author: Edge AI Team
ms.date: 2025-06-06
ms.topic: troubleshooting
estimated_reading_time: 8
keywords:
  - troubleshooting
  - common issues
  - development problems
  - deployment issues
  - environment setup
  - git workflow
  - infrastructure
  - debugging
  - solutions
---

This guide covers common issues encountered during development, testing, and deployment of the AI on Edge Flagship Accelerator. Use this as a reference for quick resolution of frequent problems.

## Development Environment Issues

### Dev Container Problems

#### Container Won't Start

**Symptoms**: Dev Container fails to build or start

**Solutions**:

1. **Check Docker Desktop**:

   ```bash
   # Verify Docker is running
   docker info

   # Check available space (containers need significant disk space)
   docker system df
   ```

2. **Clean Docker system**:

   ```bash
   # Remove unused containers and images
   docker system prune -a

   # Remove Dev Container specifically
   docker container rm $(docker container ls -aq --filter name=edge-ai)
   ```

3. **Rebuild container**:

   ```bash
   # Use VS Code Command Palette
   # Remote-Containers: Rebuild Container
   ```

#### Container Builds but Tools Missing

**Symptoms**: Container starts but required tools are not available

**Solutions**:

1. **Verify tool availability**:

   ```bash
   # Check essential tools
   terraform version
   az version
   kubectl version --client
   npm --version
   ```

2. **Update container configuration**:

   ```bash
   # Check .devcontainer/devcontainer.json for tool versions
   # Rebuild with latest base image
   ```

#### Performance Issues

**Symptoms**: Slow performance inside Dev Container

**Solutions**:

1. **Allocate more resources to Docker**:
   - Increase memory allocation in Docker Desktop settings
   - Allocate more CPU cores if available

2. **Use bind mounts efficiently**:
   - Avoid unnecessary file watchers
   - Use dockerignore for large directories

### Tool Configuration Issues

#### Azure CLI Authentication

**Symptoms**: Azure CLI commands fail with authentication errors

**Solutions**:

1. **Interactive login**:

   ```bash
   # Login and set subscription
   az login
   az account set --subscription "your-subscription-id"

   # Verify authentication
   az account show
   ```

2. **Service Principal authentication** (for CI/CD):

   ```bash
   az login --service-principal \
     -u $AZURE_CLIENT_ID \
     -p $AZURE_CLIENT_SECRET \
     --tenant $AZURE_TENANT_ID
   ```

#### Kubectl Configuration

**Symptoms**: kubectl commands fail to connect to cluster

**Solutions**:

1. **Get cluster credentials**:

   ```bash
   # For AKS cluster
   az aks get-credentials --resource-group myResourceGroup --name myAKSCluster

   # Verify connection
   kubectl cluster-info
   ```

2. **Check kubeconfig**:

   ```bash
   # View current configuration
   kubectl config view

   # List available contexts
   kubectl config get-contexts

   # Switch context
   kubectl config use-context mycontext
   ```

## Infrastructure Deployment Issues

### Terraform Issues

#### State Lock Issues

**Symptoms**: Terraform operations fail with state lock errors

**Solutions**:

1. **Wait for lock to release** (if another operation is running)

2. **Force unlock** (use carefully):

   ```bash
   # Get lock ID from error message
   terraform force-unlock <LOCK_ID>
   ```

3. **Use workspace isolation**:

   ```bash
   # Create isolated workspace for testing
   terraform workspace new test-$(date +%s)
   terraform workspace select test-$(date +%s)
   ```

#### Provider Version Conflicts

**Symptoms**: Terraform init fails with provider version errors

**Solutions**:

1. **Update provider constraints**:

   ```hcl
   # In versions.tf
   terraform {
     required_providers {
       azurerm = {
         source  = "hashicorp/azurerm"
         version = "~> 3.0"
       }
     }
   }
   ```

2. **Upgrade providers**:

   ```bash
   # Upgrade to latest compatible versions
   terraform init -upgrade

   # Lock specific versions
   terraform providers lock
   ```

#### Resource Naming Conflicts

**Symptoms**: Deployment fails due to resource name collisions

**Solutions**:

1. **Use unique naming**:

   ```hcl
   # Add random suffix
   resource "random_string" "suffix" {
     length  = 8
     special = false
     upper   = false
   }

   locals {
     unique_name = "${var.prefix}-${random_string.suffix.result}"
   }
   ```

2. **Check existing resources**:

   ```bash
   # List resources in resource group
   az resource list --resource-group myResourceGroup
   ```

### Bicep Issues

#### Template Compilation Errors

**Symptoms**: Bicep build fails with syntax errors

**Solutions**:

1. **Check syntax with detailed output**:

   ```bash
   # Build with verbose output
   az bicep build --file main.bicep --verbose

   # Lint for issues
   az bicep lint --file main.bicep
   ```

2. **Validate parameter types**:

   ```bicep
   // Ensure parameter decorators are correct
   @description('Resource location')
   @allowed(['eastus', 'westus'])
   param location string
   ```

#### Deployment Validation Failures

**Symptoms**: Template deploys but resources are not configured correctly

**Solutions**:

1. **Use what-if deployment**:

   ```bash
   # Preview changes before deployment
   az deployment group what-if \
     --resource-group myResourceGroup \
     --template-file main.bicep \
     --parameters @parameters.json
   ```

2. **Validate incrementally**:

   ```bash
   # Deploy smaller components first
   # Add resources incrementally
   ```

### Azure Resource Issues

#### Permission Denied Errors

**Symptoms**: Deployment fails with insufficient permissions

**Solutions**:

1. **Check role assignments**:

   ```bash
   # List role assignments for subscription
   az role assignment list --assignee $(az account show --query user.name -o tsv)

   # Check specific resource group
   az role assignment list --resource-group myResourceGroup
   ```

2. **Required permissions for components**:
   - **Key Vault**: Key Vault Administrator or Contributor
   - **Networking**: Network Contributor
   - **Kubernetes**: Azure Kubernetes Service Contributor
   - **Storage**: Storage Account Contributor

#### Resource Provider Registration

**Symptoms**: Deployment fails with provider not registered errors

**Solutions**:

```bash
# Register required providers
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.ContainerService

# Check registration status
az provider show --namespace Microsoft.KeyVault --query registrationState
```

## Git and Version Control Issues

### SSH Authentication Issues

**Symptoms**: Git operations fail with SSH authentication errors

**Solutions**:

1. **Generate SSH key** (if not exists):

   ```bash
   ssh-keygen -t ed25519 -C "your.email@example.com"
   ```

2. **Add key to SSH agent**:

   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```

3. **Add public key to GitHub**:
   - Copy `~/.ssh/id_ed25519.pub` to GitHub SSH keys

4. **Test SSH connection**:

   ```bash
   ssh -T git@github.com
   ```

### Branch and Merge Issues

#### Merge Conflicts

**Symptoms**: Git merge fails with conflicts

**Solutions**:

1. **Resolve conflicts manually**:

   ```bash
   # Start merge
   git merge main

   # Edit conflicted files
   # Look for <<<<<<< HEAD markers

   # Stage resolved files
   git add resolved-file.tf

   # Complete merge
   git commit
   ```

2. **Use merge tools**:

   ```bash
   # Configure merge tool
   git config --global merge.tool vimdiff

   # Launch merge tool
   git mergetool
   ```

#### Detached HEAD State

**Symptoms**: Git shows detached HEAD warnings

**Solutions**:

```bash
# Create branch from current state
git checkout -b new-branch-name

# Or discard changes and return to main
git checkout main
```

### Conventional Commit Issues

**Symptoms**: Commits don't follow conventional format

**Solutions**:

1. **Amend last commit**:

   ```bash
   # Fix most recent commit message
   git commit --amend -m "feat(terraform): add monitoring component"
   ```

2. **Interactive rebase** for multiple commits:

   ```bash
   # Rewrite last 3 commits
   git rebase -i HEAD~3
   ```

3. **Use conventional commit format**:

   ```text
   feat(scope): description
   fix(scope): description
   docs(scope): description
   chore(scope): description
   ```

## Linting and Code Quality Issues

### MegaLinter Issues

#### Linter Failures

**Symptoms**: MegaLinter reports multiple errors

**Solutions**:

1. **Run specific linters**:

   ```bash
   # Run only Terraform linting
   npx mega-linter-runner --flavor terraform

   # Run only markdown linting
   npm run mdlint
   ```

2. **Fix automatically fixable issues**:

   ```bash
   npm run lint-fix-devcontainer
   ```

3. **Review configuration**:

   ```yaml
   # Check .mega-linter.yml for disabled linters
   DISABLE:
     - COPYPASTE
     - SPELL_LYCHEE
   ```

### Markdown Linting Issues

#### Common Markdown Errors

**Symptoms**: Markdown linting fails with formatting errors

**Solutions**:

1. **MD025 (multiple H1 headings)**:

   ```markdown
   <!-- Remove duplicate H1 headings -->
   <!-- Use only one # heading per file -->
   ```

2. **MD032 (lists need blank lines)**:

   ```markdown
   Text before list

   - List item 1
   - List item 2

   Text after list
   ```

3. **MD040 (code blocks need language)**:

   ```markdown
   ```bash
   echo "Specify language for code blocks"
   ```bash
   # Add empty line before and after
   ```

### Spell Checking Issues

#### Spell Checking False Positives

**Symptoms**: cspell reports errors for technical terms

**Solutions**:

1. **Add to project dictionary**:

   ```bash
   # Add technical terms to .cspell-dictionary.txt
   echo "terraform" >> .cspell-dictionary.txt
   echo "kubernetes" >> .cspell-dictionary.txt
   ```

2. **Inline ignores**:

   ```markdown
   <!-- cspell:ignore terratest bicep -->
   This document discusses terratest and bicep.
   ```

## Security Scanning Issues

### Checkov Issues

#### Checkov False Positives

**Symptoms**: Checkov reports security issues for acceptable configurations

**Solutions**:

1. **Skip specific checks**:

   ```hcl
   # Terraform example
   resource "azurerm_storage_account" "example" {
     # checkov:skip=CKV_AZURE_33: Public access required for this use case
     public_network_access_enabled = true
   }
   ```

2. **Configure skip rules**:

   ```yaml
   # .checkov.yml
   skip-check:
     - CKV_AZURE_33
     - CKV2_AZURE_1
   ```

#### Checkov Performance Issues

**Symptoms**: Checkov scans take too long

**Solutions**:

```bash
# Scan only changed folders
npm run checkov-changes

# Scan specific directories
checkov -d src/000-cloud/010-security-identity

# Use parallel processing
checkov --external-checks-dir ./custom-checks --parallel
```

## Testing and Validation Issues

### Terratest Issues

#### Test Timeouts

**Symptoms**: Go tests fail with timeout errors

**Solutions**:

```bash
# Increase timeout
go test -v -timeout 60m ./tests/...

# Run specific test
go test -v -run TestSpecificFunction -timeout 30m
```

#### Azure Authentication in Tests

**Symptoms**: Tests fail with Azure authentication errors

**Solutions**:

```go
// Use environment variables for authentication
// Set in CI/CD pipeline or locally
// AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID
```

### Resource Cleanup Issues

**Symptoms**: Test resources are not cleaned up

**Solutions**:

1. **Manual cleanup**:

   ```bash
   # List test resource groups
   az group list --query "[?contains(name, 'test')].name" -o tsv

   # Delete test resources
   az group delete --name test-resource-group --yes --no-wait
   ```

2. **Automated cleanup script**:

   ```bash
   #!/bin/bash
   # cleanup-test-resources.sh

   # Delete resource groups older than 24 hours with "test" in name
   az group list --query "[?contains(name, 'test')]" -o json | \
   jq -r '.[] | select(.properties.provisioningState == "Succeeded") | .name' | \
   xargs -I {} az group delete --name {} --yes --no-wait
   ```

## Getting Help

### Self-Help Resources

1. **Documentation**:
   - Check component README files
   - Review existing GitHub issues
   - Consult Azure documentation

2. **Debugging**:
   - Enable verbose logging
   - Use step-by-step troubleshooting
   - Isolate the problem

3. **Testing**:
   - Use minimal reproduction cases
   - Test in isolated environments
   - Verify assumptions

### GitHub Copilot Assistance

Use GitHub Copilot for troubleshooting:

```bash
# In VS Code chat, describe your issue:
"I'm getting a Terraform state lock error when deploying. How can I resolve this?"

"Checkov is reporting CKV_AZURE_33 for my storage account. Is this a false positive?"

"My Dev Container won't start and Docker Desktop shows an error. What should I check?"
```

### Community Support

1. **GitHub Issues**:
   - Search existing issues first
   - Create new issue with detailed information
   - Include error messages and environment details

2. **Discussion Forums**:
   - Use GitHub Discussions for general questions
   - Share solutions that worked for you
   - Help others with similar issues

### Creating Effective Bug Reports

Include this information when reporting issues:

```markdown
**Environment:**
- OS: [Windows 11/macOS 13/Ubuntu 22.04]
- Docker Desktop version:
- VS Code version:
- Dev Container: [Yes/No]

**Tools:**
- Terraform version:
- Azure CLI version:
- kubectl version:

**Problem Description:**
Clear description of the issue

**Steps to Reproduce:**
1. Step one
2. Step two
3. See error

**Expected Behavior:**
What should happen

**Actual Behavior:**
What actually happens

**Error Messages:**
[Include full error messages]

**Additional Context:**
Any other relevant information
```

### Escalation Process

For critical issues:

1. **Immediate help**: Use GitHub Copilot for quick guidance
2. **Team support**: Reach out to project maintainers
3. **Security issues**: Use private reporting for vulnerabilities
4. **Blocking issues**: Create high-priority GitHub issues

Remember: Most issues have been encountered before. Search existing documentation and issues first, then ask for help with specific details about your situation.

For more information about development workflows, see the [Development Environment](./development-environment.md) and [Contributing Guidelines](./contributing.md).

*🤖 Crafted with precision by ✨Copilot following brilliant human instruction, then carefully refined by our team of discerning human reviewers.*
