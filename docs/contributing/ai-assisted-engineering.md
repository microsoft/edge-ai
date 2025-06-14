---
title: AI-Assisted Engineering
description: Guide for using AI-powered tools like GitHub Copilot when working with the AI on Edge Flagship Accelerator
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: how-to
estimated_reading_time: 5
keywords:
  - ai-assisted engineering
  - github copilot
  - development workflows
---

## AI-Assisted Engineering

This guide covers how to effectively use AI-powered tools, particularly GitHub Copilot, when working with the AI on Edge Flagship Accelerator.

## Official Documentation

For comprehensive information about GitHub Copilot and VS Code integration, refer to the official documentation:

- **[GitHub Copilot Documentation](https://docs.github.com/en/copilot)** - Complete guide to using GitHub Copilot
- **[VS Code GitHub Copilot Extension](https://code.visualstudio.com/docs/editor/github-copilot)** - VS Code specific features and setup
- **[GitHub Copilot Chat](https://docs.github.com/en/copilot/github-copilot-chat)** - Using Copilot Chat for development assistance

## Project-Specific AI Resources

This repository includes specialized configurations and resources to enhance AI assistance:

### Copilot Instructions

The repository includes comprehensive GitHub Copilot instructions in `.github/copilot-instructions.md` that provide:

- **Automatic Context Discovery**: AI automatically finds and uses relevant project context
- **Convention Enforcement**: Ensures all AI-generated code follows project standards
- **Component Understanding**: Deep knowledge of the project's component and blueprint architecture
- **Markdown Standards**: Automatic compliance with documentation formatting requirements

These instructions are automatically applied to every Copilot interaction, ensuring consistent, high-quality assistance.

## Repository AI Guidance Files

The project contains specialized AI guidance files organized across different directories:

### Core Guidance (`/copilot/`)

Comprehensive guidance files referenced by the main copilot instructions:

- **`deploy.md`** - Deployment guidance and best practices
- **`getting-started.md`** - Getting started guidance for new contributors
- **`python-script.md`** - Python scripting standards and conventions
- **`csharp-tests.md`** - C# testing standards and practices
- **`terraform/`** - Terraform development guidance and standards
- **`bicep/`** - Bicep development guidance and standards
- **`csharp/`** - C# development guidance and standards

### Context Instructions (`/.github/instructions/`)

Instruction files designed to be attached to Copilot context using **Add Context > Instructions**:

- **`bicep.instructions.md`** - Bicep-specific instructions for Copilot
- **`csharp.instructions.md`** - C# development instructions
- **`terraform.instructions.md`** - Terraform development instructions
- **`commit-message.instructions.md`** - Commit message formatting guidance
- **`task-plan.instructions.md`** - Task planning instructions

### Reusable Prompts (`/.github/prompts/`)

Prompt files for specific tasks that can be invoked using `/prompt-name` in Copilot chat:

- **`adr-create.prompt.md`** - Architecture Decision Record creation
- **`csharp-tests.prompt.md`** - C# test development prompts
- **`deploy.prompt.md`** - Deployment-related prompts
- **`edge-ai-project-planning.prompt.md`** - Project planning guidance
- **`getting-started.prompt.md`** - Getting started prompts
- **`pull-request.prompt.md`** - Pull request creation assistance
- **`python-script.prompt.md`** - Python scripting prompts
- **`task-implementer.prompt.md`** - Task implementation guidance
- **`task-planner.prompt.md`** - Task planning prompts
- **`terraform-from-blueprint.prompt.md`** - Terraform blueprint conversion

## Using Repository AI Resources

### Applying Context Instructions

1. Use Copilot Chat: **Add Context > Instructions > Select the instruction file**
2. Add your specific context (files, folders, etc.)
3. Provide your development prompt
4. Instructions are automatically applied to ensure consistency with project standards

### Invoking Reusable Prompts

1. In VS Code, use Command Palette: **Chat: Run Prompt** and select desired prompt
2. Or type `/prompt-name` directly in Copilot chat (e.g., `/pull-request`, `/task-planner`)
3. Follow the guided workflow provided by the prompt

## Essential Project Prompts

### Pull Request Generation (`/pull-request`)

- Generates comprehensive PR descriptions following project standards
- Ensures proper documentation updates and review checklist completion
- Options: `includeMarkdown=true`, `branch=feat/branch-name`

### Task Planning and Implementation (`/task-planner`, `/task-implementer`)

- **`/task-planner`**: Creates structured development plans with phases and tasks
- **`/task-implementer`**: Executes plans and tracks progress through each phase
- Files stored in `./.copilot-tracking/` (excluded from git)
- Works with the `task-plan.instructions.md` for enhanced guidance

### Deployment Assistance (`/deploy`)

- Provides deployment guidance and workflows specific to project blueprints
- Infrastructure deployment assistance following project conventions

### Architecture Decision Records (`/adr-create`)

- Guided ADR creation following project templates
- Ensures proper documentation of architectural decisions

## Project Structure Integration

The AI resources are designed to work with the project's specific structure:

### Component Development

- AI understands the decimal naming convention (e.g., `000-cloud`, `010-security-identity`)
- Recognizes internal modules and their scoping rules
- Follows deployment patterns from CI directories and blueprints

### Blueprint Creation

- AI can suggest component combinations based on existing blueprints
- Understands output-to-input mapping between components
- Follows blueprint documentation requirements

### Framework-Specific Guidance

- **Terraform**: Module organization, variable patterns, testing with Terratest
- **Bicep**: Parameter definitions, module structure, Azure resource patterns
- **C#**: Testing standards, project structure, dependency patterns

## GitHub Copilot for Azure Extension

When using the Dev Container, the [GitHub Copilot for Azure (Preview)](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azure-github-copilot) extension provides:

- **Azure-specific agents**: Use `#azure...` tags for Azure-specific assistance
- **Resource schema**: `#azureBicepGetResourceSchema` for latest Bicep schemas
- **Best practices**: `#azureTerraformBestPractices` for Terraform guidance
- **Documentation**: `#azureRetrieveMsLearnDocumentations` for up-to-date Azure docs

## Additional Resources

- [Project Coding Conventions](coding-conventions.md) - Standards that AI tools follow
- [Development Environment](development-environment.md) - Dev Container setup with AI tools
- [Troubleshooting](troubleshooting.md) - Common issues and solutions

*For general GitHub Copilot usage, refer to the [official documentation](https://docs.github.com/en/copilot).*

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
