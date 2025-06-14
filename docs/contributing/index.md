---
title: Contributor Resources
description: Comprehensive developer documentation and resources for contributing to the AI on Edge Flagship Accelerator, including guidelines, coding standards, testing, and development environment setup
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: hub-page
estimated_reading_time: 4
keywords:
  - contributing
  - developer resources
  - contribution guidelines
  - coding standards
  - development environment
  - testing
  - troubleshooting
  - ai-assisted engineering
---

## Contributor Resources

Welcome to the comprehensive contributor resources for the AI on Edge Flagship Accelerator. This section consolidates all developer-focused documentation, tools, and guidelines for effective contribution to the project.

## Essential Reading

### 📋 [Contributing Guidelines](contributing.md)

Complete guide to participating in the project, including:

- Code of conduct and community guidelines
- Bug reporting and enhancement suggestions
- First contribution guidance
- Documentation improvement processes

### 🛠️ [Development Environment](development-environment.md)

Comprehensive Dev Container setup and configuration:

- Complete Dev Container configuration guide
- Git setup and SSH configuration
- Available tools and scripts
- Maintenance and troubleshooting

### 📏 [Coding Conventions](coding-conventions.md)

Detailed coding standards and best practices:

- Folder structure and naming conventions
- Infrastructure as Code standards (Terraform and Bicep)
- Git workflow and conventional commits
- Documentation requirements

### 🤖 [AI-Assisted Engineering](ai-assisted-engineering.md)

Maximize productivity with GitHub Copilot:

- Repository-specific prompt files
- Task planning and implementation workflows
- Pull request automation
- Best practices for AI-assisted development

## Development Workflows

### 🔄 [Task Planning Process](task-planning.md)

Structured approach to feature development:

- Using task planner prompts
- Creating and managing plan files
- Implementation tracking and notes
- Progress monitoring

### 🔍 [Testing and Validation](testing-validation.md)

Comprehensive testing requirements:

- Component testing procedures
- Integration testing strategies
- Security scanning and compliance
- Automated testing in CI/CD

### 🚀 [Deployment and Release](deployment-release.md)

Understanding deployment processes:

- Component deployment procedures
- Blueprint testing and validation
- Release management
- Versioning strategies

## Code Quality and Standards

### 🧹 [Linting and Code Quality](linting-quality.md)

Automated code quality assurance:

- MegaLinter configuration and usage
- Language-specific linting tools
- Pre-commit validation
- Fixing common issues

### 🔒 [Security Guidelines](security-guidelines.md)

Security best practices for contributors:

- Secure coding practices
- Secret management
- Vulnerability scanning
- Compliance requirements

### 📊 [Performance Considerations](performance.md)

Optimizing components and blueprints:

- Resource optimization techniques
- Performance testing
- Monitoring and observability
- Scaling considerations

## Troubleshooting and Support

### 🐛 [Common Issues and Solutions](troubleshooting.md)

Frequently encountered problems and resolutions:

- Dev Container issues
- Terraform and Bicep problems
- Git and authentication issues
- Build and deployment failures

### 💬 [Getting Help](getting-help.md)

Resources for support and assistance:

- Using GitHub Copilot effectively
- Community support channels
- Escalation procedures
- Documentation feedback

## Advanced Topics

### 🏗️ [Architecture Decisions](architecture.md)

Understanding project architecture:

- Component design principles
- Blueprint architecture patterns
- Technology choices and rationale
- Evolution and migration strategies

### 🔧 [Customization and Extensions](customization.md)

Extending the platform:

- Creating custom components
- Extending existing functionality
- Plugin development
- Integration patterns

### 📈 [Monitoring and Observability](observability.md)

Comprehensive monitoring setup:

- Logging strategies
- Metrics collection
- Alerting and notifications
- Performance monitoring

## Quick Reference

### Command Reference

```bash
# Development environment
npm run lint                   # Run all linters
npm run lint-fix               # Fix common issues
npm run test                   # Run test suites

# Git workflow
git commit -m "feat: description"  # Conventional commit
gh pr create --title "feat: ..."  # Create pull request

# Infrastructure validation
terraform validate             # Validate Terraform
az bicep build --file main.bicep  # Build Bicep template
```

### Key Files and Locations

| Resource      | Location                          | Purpose                    |
|---------------|-----------------------------------|----------------------------|
| Components    | `src/000-cloud/`, `src/100-edge/` | Infrastructure components  |
| Blueprints    | `blueprints/`                     | Deployment templates       |
| Documentation | `docs/`                           | Project documentation      |
| Scripts       | `scripts/`                        | Automation and utilities   |
| Tests         | `tests/`                          | Test suites and validation |
| Prompts       | `.github/prompts/`                | GitHub Copilot prompts     |

### Useful Links

- **[Getting Started Guides](../getting-started/)** - Initial setup and user guides
- **[Build & CI/CD Documentation](../build-cicd/)** - Pipeline and automation guides
- **[Observability Documentation](../observability/)** - Monitoring and debugging
- **[Component Library](../../src/)** - Browse infrastructure components
- **[Blueprint Catalog](../../blueprints/)** - Deployment solution templates
- **[Project Repository][project-repo]** - Main repository
- **[Azure IoT Operations Documentation][iot-ops-docs]** - Platform documentation
- **[Terraform Documentation][terraform-docs]** - Infrastructure as Code
- **[Bicep Documentation][bicep-docs]** - Azure Resource Manager templates
- **[GitHub Documentation Style Guide][github-style]** - Documentation standards

## Contributing to This Documentation

This contributor documentation is a living resource. Help us improve it by:

1. **Identifying gaps**: What information is missing or unclear?
2. **Suggesting improvements**: How can we make these guides more helpful?
3. **Contributing examples**: Share real-world examples and case studies
4. **Updating content**: Keep information current with project evolution

To contribute to these docs, follow our standard [development workflow](coding-conventions.md#git-workflow) and submit pull requests with your improvements.

---

*This documentation is part of the AI on Edge Flagship Accelerator project. For the latest updates and comprehensive resources, visit our [project repository][project-repo].*

[project-repo]: {{REPO_URL}}
[iot-ops-docs]: https://learn.microsoft.com/azure/iot-operations/
[terraform-docs]: https://www.terraform.io/docs
[bicep-docs]: https://docs.microsoft.com/azure/azure-resource-manager/bicep/
[github-style]: https://github.com/github/docs/blob/main/contributing/content-style-guide.md

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
