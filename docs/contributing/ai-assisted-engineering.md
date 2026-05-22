---
title: AI-Assisted Engineering
description: Guide for using AI-powered tools like GitHub Copilot when working with the AI on Edge Flagship Accelerator
author: Edge AI Team
ms.date: 2026-05-15
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
- **`bicep/bicep.md`** - Edge AI Bicep deployment guidance
- **`bicep/bicep-standards.md`** - Edge AI Bicep patterns and best practices
- **`terraform/terraform.md`** - Edge AI Terraform deployment guidance
- **`terraform/terraform-standards.md`** - Edge AI Terraform patterns and best practices

> **Note**: Shared coding standards for Bash, Bicep, C#, commit messages, Markdown, Python scripting, Rust, and Terraform are provided by the [hve-core](https://github.com/microsoft/hve-core) VS Code extension and loaded automatically when installed.

### Context Instructions (`/.github/instructions/`)

Instruction files designed to be attached to Copilot context using **Add Context > Instructions**:

| File Name                                         | Context/Language     | Description                                                                   |
|---------------------------------------------------|----------------------|-------------------------------------------------------------------------------|
| `application.instructions.md`                     | Edge applications    | Edge application creation, import, and management guidance                    |
| `build-documentation.instructions.md`             | Build documentation  | Build and CI/CD documentation requirements                                    |
| `css.instructions.md`                             | Documentation CSS    | Modular CSS architecture and documentation site styling standards             |
| `javascript.instructions.md`                      | JavaScript           | Edge AI JavaScript guidance for backend, frontend, and utility code           |
| `rust-crate-registration.instructions.md`         | Rust CI registration | Rust crate registration requirements for CI test, coverage, and Codecov       |
| `tf-variable-consistency-manager.instructions.md` | Terraform governance | Terraform variable validation and standardization workflow                    |
| `wasm-build-deploy.instructions.md`               | WASM operators       | WASM operator build, deploy, graph schema, and validation standards           |
| `wasm-operator-templates.instructions.md`         | WASM operators       | Rust-based WASM operator templates                                            |
| `wasm-sdk-reference.instructions.md`              | WASM operators       | WASM SDK reference patterns for Azure IoT Operations dataflow graph operators |

> **Note**: Shared task implementation, task research, task review, and learning coaching workflows are available through the [hve-core](https://github.com/microsoft/hve-core) VS Code extension.

### Reusable Prompts (`/.github/prompts/`)

Prompt files for specific tasks that can be invoked using `/prompt-name` in Copilot chat:

| Prompt Name                                 | Invocation                         | Description                                   | Use Case                                             |
|---------------------------------------------|------------------------------------|-----------------------------------------------|------------------------------------------------------|
| `deploy.prompt.md`                          | `/deploy`                          | Deployment workflows and best practices       | Infrastructure deployment assistance                 |
| `getting-started.prompt.md`                 | `/getting-started`                 | Project onboarding and initial setup guidance | New contributor onboarding                           |
| `edge-ai-project-planning.prompt.md`        | `/edge-ai-project-planning`        | Edge AI project discovery and planning        | Scoping edge AI scenarios and solution capabilities  |
| `iotops-version-upgrade.prompt.md`          | `/iotops-version-upgrade`          | Azure IoT Operations version upgrade process  | Updating IoT Ops components to latest versions       |
| `terraform-from-blueprint.prompt.md`        | `/terraform-from-blueprint`        | Converting blueprints to Terraform            | Translating blueprint designs to infrastructure code |
| `tf-variable-consistency-manager.prompt.md` | `/tf-variable-consistency-manager` | Terraform variable consistency workflow       | Standardizing Terraform variables across components  |

> **Note**: Additional prompts for ADR creation and prompt engineering are available through the [hve-core](https://github.com/microsoft/hve-core) VS Code extension.

### Enhanced Custom Agents (`/.github/agents/`)

Advanced agent files with comprehensive tool access for specialized coaching and workflow assistance:

- **`wasm-operator-builder.agent.md`** - Rust-based WebAssembly operator implementation for Azure IoT Operations dataflow graphs

Use the [Edge AI Project Planning prompt](../../.github/prompts/edge-ai-project-planning.prompt.md) for project discovery, scoping, and solution framing.

> **Note**: Shared agents for ADR creation, task planning, task research, PR review, security planning, workback planning, implementation support, and prompt engineering are available through the [hve-core](https://github.com/microsoft/hve-core) VS Code extension.

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
1. **Choose Local Edge AI Resources**: Select repository agents for WASM operator development or the project planning prompt for project scoping
1. **Use Shared HVE Core Agents**: Use the [hve-core](https://github.com/microsoft/hve-core) extension for ADR creation, task planning, task research, PR review, security planning, workback planning, implementation support, and prompt engineering
1. **Enhanced Capabilities**: Custom agents have comprehensive tool access for research, file editing, and system interaction

#### Task Planning and Implementation

- **Task Planner Custom Agent**: Access advanced planning capabilities through the [hve-core](https://github.com/microsoft/hve-core) VS Code extension
  - Creates structured development plans with phases and tasks
  - Performs research to gather context for comprehensive planning
  - Generates documentation in `./.copilot-tracking/plans/` (excluded from git)

- **Task Implementor Agent**: Access implementation workflows through the [hve-core](https://github.com/microsoft/hve-core) VS Code extension
  - Provides guidance for executing plans and tracking progress
  - Works with task planning outputs for coordinated development flow
  - Follows standardized workflows for consistent implementation practices
  - Uses `.copilot-tracking/plans/`, `.copilot-tracking/details/`, and `.copilot-tracking/changes/` artifacts for implementation tracking

### Learning AI Coaching Integration

Explore advanced AI-assisted engineering practices through our **[Learning Platform](/learning/)**:

#### Interactive Learning Support

- **Task Check-offs**: Mark progress and track learning automatically
- **Coaching Hints**: Get contextual help when stuck on exercises
- **Smart Guidance**: Personalized coaching based on your development patterns
- **Skill Assessment**: AI-powered recommendations for your next learning steps

#### Getting Started with AI Coaching

1. **Launch Training Mode**: Run `npm run docs` to access the learning platform
2. **Select Coaching Mode**: Use the learning platform guidance to choose the appropriate coaching flow
3. **Start Learning**: Say "I'm working on learning and want interactive coaching"
4. **Get Personalized Path**: Take the skill assessment for customized kata recommendations

Learning coaching resources are pre-configured and ready to use in this repository. Shared advanced agents are available through the [hve-core](https://github.com/microsoft/hve-core) VS Code extension.

## Essential Project Prompts

### Pull Request Generation (`/pull-request`)

- Generates comprehensive PR descriptions following project standards
- Ensures proper documentation updates and review checklist completion
- Options: `includeMarkdown=true`, `branch=feat/branch-name`

### Task Planning

- **Task Planner**: Available through the [hve-core](https://github.com/microsoft/hve-core) VS Code extension
- Files stored in `./.copilot-tracking/` (excluded from git)
- Works with the HVE Core Task Implementor agent for tracked implementation

### Deployment Assistance (`/deploy`)

- Provides deployment guidance and workflows specific to project blueprints
- Infrastructure deployment assistance following project conventions

### Architecture Decision Records

- Guided ADR creation is available through the [hve-core](https://github.com/microsoft/hve-core) VS Code extension
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
