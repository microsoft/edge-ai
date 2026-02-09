---
title: AI-Assisted Engineering
description: Guide for using AI-powered tools like GitHub Copilot when working with the AI on Edge Flagship Accelerator
author: Edge AI Team
ms.date: 2025-07-18
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
- **`bicep/bicep.md`** - Bicep development guidance and standards
- **`bicep/bicep-standards.md`** - Bicep coding standards and best practices
- **`terraform/terraform.md`** - Terraform development guidance and standards
- **`terraform/terraform-standards.md`** - Terraform coding standards and best practices

> **Note**: Comprehensive guidance for Python scripting, Bash, and C# conventions are provided by the [hve-core](https://github.com/microsoft/hve-core) VS Code extension and loaded automatically when installed.

### Context Instructions (`/.github/instructions/`)

Instruction files designed to be attached to Copilot context using **Add Context > Instructions**:

| File Name                               | Context/Language     | Description                                                                             |
|-----------------------------------------|----------------------|-----------------------------------------------------------------------------------------|
| `bash.instructions.md`                  | Bash/Shell Scripting | Comprehensive guidance for bash script development and shell command execution          |
| `bicep.instructions.md`                 | Azure Bicep          | Infrastructure as Code implementation guidance for Azure Bicep development              |
| `commit-message.instructions.md`        | Git/Version Control  | Standardized commit message formatting using Conventional Commit patterns               |
| `csharp.instructions.md`                | C#/.NET              | Development standards and practices for C# code implementation                          |
| `learning-coach-schema.instructions.md` | Learning             | Instructions for AI coaches managing learner progress tracking in the Learning platform |
| `python-script.instructions.md`         | Python               | Python scripting standards and conventions for automation and tooling                   |
| `shell.instructions.md`                 | Shell Environments   | General shell environment and command-line interface guidance                           |
| `task-implementation.instructions.md`   | Task Management      | Systematic process for implementing comprehensive task plans and tracking progress      |
| `terraform.instructions.md`             | Terraform            | Infrastructure as Code implementation guidance for HashiCorp Terraform development      |

### Reusable Prompts (`/.github/prompts/`)

Prompt files for specific tasks that can be invoked using `/prompt-name` in Copilot chat:

| Prompt Name                          | Invocation                  | Description                                   | Use Case                                             |
|--------------------------------------|-----------------------------|-----------------------------------------------|------------------------------------------------------|
| `csharp-tests.prompt.md`             | `/csharp-tests`             | C# test development guidance                  | Creating unit and integration tests                  |
| `deploy.prompt.md`                   | `/deploy`                   | Deployment workflows and best practices       | Infrastructure deployment assistance                 |
| `getting-started.prompt.md`          | `/getting-started`          | Project onboarding and initial setup guidance | New contributor onboarding                           |
| `iotops-version-upgrade.prompt.md`   | `/iotops-version-upgrade`   | Azure IoT Operations version upgrade process  | Updating IoT Ops components to latest versions       |
| `python-script.prompt.md`            | `/python-script`            | Python scripting standards and patterns       | Python automation and scripting                      |
| `terraform-from-blueprint.prompt.md` | `/terraform-from-blueprint` | Converting blueprints to Terraform            | Translating blueprint designs to infrastructure code |

> **Note**: Additional prompts for ADR creation and prompt engineering are available through the [hve-core](https://github.com/microsoft/hve-core) VS Code extension.

### Enhanced Custom Agents (`/.github/agents/`)

Advanced agent files with comprehensive tool access for specialized coaching and workflow assistance:

- **`adr-creation.agent.md`** - Interactive architectural decision record creation with comprehensive research and analysis capabilities
- **`edge-ai-project-planner.agent.md`** - Edge AI project planning and solution architecture guidance
- **`learning-kata-coach.agent.md`** - Interactive kata coaching with enhanced tool access
- **`learning-lab-coach.agent.md`** - Complex training lab coaching for multi-component systems
- **`security-plan-creator.agent.md`** - Security planning and assessment guidance for project implementations

> **Note**: Task planning and prompt engineering agents are available through the [hve-core](https://github.com/microsoft/hve-core) VS Code extension.

## Using Repository AI Resources

### Applying Context Instructions

1. Use Copilot Chat: **Add Context > Instructions > Select the instruction file**
2. Add your specific context (files, folders, etc.)
3. Provide your development prompt
4. Instructions are automatically applied to ensure consistency with project standards

### Invoking Reusable Prompts

1. In VS Code, use Command Palette: **Chat: Run Prompt** and select desired prompt
2. Or type `/prompt-name` directly in Copilot chat (e.g., `/pull-request`, `/getting-started`)
3. Follow the guided workflow provided by the prompt

### Using Enhanced Custom Agents

Custom agents provide specialized AI coaching with enhanced tool access, changing the system prompt in addition to the instructions:

1. **Reference Custom Agents**: Use the agent drop-down in Copilot Chat to select a custom agent

1. **Learning Coaching**:

- **Kata Coach**: `#file:/.github/agents/learning-kata-coach.agent.md` for focused practice exercises
- **Lab Coach**: `#file:/.github/agents/learning-lab-coach.agent.md` for complex training labs

1. **Enhanced Capabilities**: Custom agents have comprehensive tool access for research, file editing, and system interaction

1. **Coaching Methodology**: Follows OpenHack-style discovery-based learning with systematic guidance

#### Task Planning and Implementation

- **Task Planner Custom Agent**: Access advanced planning capabilities through the [hve-core](https://github.com/microsoft/hve-core) VS Code extension
  - Creates structured development plans with phases and tasks
  - Performs research to gather context for comprehensive planning
  - Generates documentation in `./.copilot-tracking/plans/` (excluded from git)

- **Task Implementation Instructions**: Enhance implementation with `task-implementation.instructions.md` context instructions
  - Provides guidance for executing plans and tracking progress
  - Works with task planning outputs for coordinated development flow
  - Follows standardized workflows for consistent implementation practices
  - When you select a file in the `.copilot-tracking/plans/` directory, Copilot will automatically apply the task implementation instructions context

### Learning AI Coaching Integration

Explore advanced AI-assisted engineering practices through our **[Learning Platform](/learning/)**:

#### Interactive Learning Support

- **✅ Task Check-offs**: Mark progress and track learning automatically
- **🆘 Coaching Hints**: Get contextual help when stuck on exercises
- **🧭 Smart Guidance**: Personalized coaching based on your development patterns
- **📊 Skill Assessment**: AI-powered recommendations for your next learning steps

#### Getting Started with AI Coaching

1. **Launch Training Mode**: Run `npm run docs` to access the learning platform
2. **Select Coaching Mode**: Choose "Learning Kata Coach" in GitHub Copilot Chat
3. **Start Learning**: Say "I'm working on learning and want interactive coaching"
4. **Get Personalized Path**: Take the skill assessment for customized kata recommendations

All Learning coaching modes are pre-configured and ready to use immediately in this repository. All advanced agent prompts can be easily copied into your own project for immediate AI-assisted engineering acceleration.

## Essential Project Prompts

### Pull Request Generation (`/pull-request`)

- Generates comprehensive PR descriptions following project standards
- Ensures proper documentation updates and review checklist completion
- Options: `includeMarkdown=true`, `branch=feat/branch-name`

### Task Planning

- **Task Planner**: Available through the [hve-core](https://github.com/microsoft/hve-core) VS Code extension
- Files stored in `./.copilot-tracking/` (excluded from git)
- Works with the `task-implementation.instructions.md` for enhanced guidance

### Deployment Assistance (`/deploy`)

- Provides deployment guidance and workflows specific to project blueprints
- Infrastructure deployment assistance following project conventions

### Architecture Decision Records

- Guided ADR creation using the `adr-creation` custom agent
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
