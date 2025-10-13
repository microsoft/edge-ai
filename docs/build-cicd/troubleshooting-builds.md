---
title: Troubleshooting builds
description: Quick troubleshooting guide for build failures, pipeline issues, and CI/CD problems in the Edge AI Accelerator project.
author: Edge AI Team
ms.date: 06/13/2025
ms.topic: hub-page
keywords:
  - troubleshooting
  - build failures
  - pipeline issues
  - ci/cd
  - authentication
  - terraform
  - bicep
estimated_reading_time: 3
---

## Troubleshooting Builds

Quick solutions for common build and CI/CD issues in the Edge AI Accelerator project.

## Quick diagnostics

### Authentication issues

**Symptoms**: `Failed to acquire token`, `Access denied`, `Authentication failed`

**Solutions**:

- Verify Azure CLI login: `az account show`
- Check service principal permissions: `az role assignment list --assignee $ARM_CLIENT_ID`
- Validate GitHub token scopes in repository settings
- Ensure Key Vault access policies are configured correctly

### Dependency issues

**Symptoms**: `Command not found`, `Package not found`, `Version conflict`

**Solutions**:

- Install missing tools: Use `./scripts/install-terraform-docs.sh` for Terraform docs
- Clear caches: Remove `~/.terraform.d/plugin-cache`, `~/.cache/pip`, `~/.npm`
- Reinstall dependencies: Run `terraform init -upgrade`, `pip install --force-reinstall -r requirements.txt`
- Azure Linux containers: Import `/etc/pki/rpm-gpg/MICROSOFT-RPM-GPG-KEY` before running `tdnf` to avoid `Header V4 RSA/SHA256 Signature ... NOKEY`
- Check tool versions: `terraform --version`, `bicep --version`, `az --version`

### Configuration issues

**Symptoms**: `Invalid configuration`, `Validation failed`, `Parameter error`

**Solutions**:

- Validate Terraform: `terraform validate && terraform fmt -check`
- Validate Bicep: `bicep build main.bicep && bicep lint main.bicep`
- Check parameter files and variable definitions
- Test templates in isolation with minimal configurations

## Platform-specific issues

### GitHub Actions

**Common problems**:

- **Workflow syntax**: Use GitHub CLI to validate workflows
- **Runner issues**: Check runner OS, available space, and memory
- **Matrix failures**: Verify matrix configuration and include/exclude patterns
- **Action failures**: Validate action inputs and dependencies

**Debugging**:

- Enable debug logging: Set `ACTIONS_STEP_DEBUG: true` and `ACTIONS_RUNNER_DEBUG: true`
- Add conditional debug steps with `if: failure()`

### Azure DevOps

**Common problems**:

- **Agent issues**: Verify agent pool availability and capabilities
- **Service connections**: Check authentication and permissions
- **Pipeline syntax**: Validate YAML syntax and task versions
- **Variable groups**: Ensure variables are properly configured

**Debugging**:

- Enable system diagnostics
- Check agent logs and pipeline run details
- Validate service connection permissions

## Script and security scanning

### Script failures

**Common causes**:

- **PowerShell**: Execution policy, module dependencies, parameter validation
- **Bash**: File permissions, environment variables, tool availability
- **Python**: Virtual environments, package versions, import errors

**Solutions**:

- Check execution policies and permissions
- Validate required tools and dependencies are installed
- Use appropriate script debugging flags (`-x` for bash, `-Debug` for PowerShell)

### Security scanning

**Common issues**:

- **Checkov failures**: Update policies, add skip annotations for false positives
- **Secret detection**: Review and remediate flagged secrets, update .gitignore
- **Vulnerability scanning**: Update dependencies, apply security patches

## Performance optimization

### Build performance

**Common bottlenecks**:

- Dependency downloads and caching
- Large artifact uploads/downloads
- Parallel job limitations
- Resource constraints (CPU, memory, disk)

**Solutions**:

- Enable caching for dependencies and build artifacts
- Use matrix strategies for parallel execution
- Optimize container images and reduce layer count
- Configure appropriate timeouts and retry policies

## General debugging approach

1. **Identify**: Check error messages and failure points
2. **Isolate**: Test components individually
3. **Validate**: Verify configuration and dependencies
4. **Debug**: Enable verbose logging and diagnostics
5. **Fix**: Apply targeted solutions
6. **Prevent**: Implement monitoring and validation checks

## Quick reference commands

```bash
# Azure validation
az account show
az role assignment list --assignee $ARM_CLIENT_ID

# Tool validation
terraform --version && terraform validate
bicep --version && bicep build main.bicep
az --version

# Clean and reinstall
rm -rf ~/.terraform.d/plugin-cache ~/.cache/pip ~/.npm
terraform init -upgrade
pip install --force-reinstall -r requirements.txt
```

## Related documentation

- [GitHub Actions Workflows](./github-actions.md) - GitHub Actions workflow documentation
- [Azure DevOps Pipelines](./azure-devops.md) - Azure DevOps pipeline documentation
- [Security Scanning Guide](./security-scanning.md) - Security scanning troubleshooting
- [Build Scripts Guide](./build-scripts.md) - Build script troubleshooting

## Azure DevOps Pipeline Debugging

**Agent environment issues**:

```yaml
- task: PowerShell@2
  displayName: 'Debug Agent Environment'
  inputs:
    script: |
      Write-Host "Agent Name: $(Agent.Name)"
      Write-Host "Agent OS: $(Agent.OS)"
      Write-Host "Build Directory: $(Build.SourcesDirectory)"
      Write-Host "Available Space: $(Get-Volume)"
      Get-ChildItem Env: | Sort-Object Name
```

**Variable group issues**:

```yaml
# Validate variable groups
- task: PowerShell@2
  displayName: 'Validate Variables'
  inputs:
    script: |
      if (-not $env:ARM_CLIENT_ID) {
        Write-Error "ARM_CLIENT_ID not found in variable group"
        exit 1
      }
      Write-Host "Variables loaded successfully"
```

**Template issues**:

```yaml
# Debug template parameters
- template: security-template.yml
  parameters:
    debugMode: true
    verboseOutput: true
```

---

*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
