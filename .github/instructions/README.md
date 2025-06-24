---
title: GitHub Copilot Instructions
description: Context-specific development instructions for systematic AI-assisted implementation
author: Edge AI Team
ms.date: 06/18/2025
ms.topic: reference
estimated_reading_time: 3
keywords:
  - github copilot
  - instructions
  - development standards
  - ai assistance
  - context-specific guidance
---

This directory contains context-specific instruction files designed to be used with GitHub Copilot's "Add Context > Instructions" feature for systematic AI-assisted development.

## Overview

Instructions provide focused guidance for specific development contexts, technologies, and workflows. They are applied directly to Copilot conversations to ensure consistent adherence to project standards and best practices.

## Available Instructions

### [Bash Instructions](bash.instructions.md)

Comprehensive guidance for bash script development and shell command execution.

- **Context**: Shell scripting, automation scripts, CI/CD workflows
- **Scope**: Bash syntax standards, error handling, script structure
- **Apply When**: Writing bash scripts or shell automation

### [Bicep Instructions](bicep.instructions.md)

Infrastructure as Code implementation guidance for Azure Bicep development.

- **Context**: Azure infrastructure deployment, Bicep templates
- **Scope**: Bicep syntax, module organization, deployment patterns
- **Apply When**: Creating or modifying Bicep infrastructure code

### [C# Instructions](csharp.instructions.md)

Development standards and practices for C# code implementation.

- **Context**: C# application development, .NET projects
- **Scope**: Code structure, naming conventions, best practices
- **Apply When**: Writing C# code or .NET applications

### [Commit Message Instructions](commit-message.instructions.md)

Standardized commit message formatting using Conventional Commit patterns.

- **Context**: Git commit message creation
- **Scope**: Message format, types, scopes, standardization
- **Apply When**: Creating commit messages or reviewing version control

### [Shell Instructions](shell.instructions.md)

General shell environment and command-line interface guidance.

- **Context**: Shell operations, command-line tools, system interaction
- **Scope**: Shell usage patterns, command structure, environment setup
- **Apply When**: Working with shell environments and CLI tools

### [Task Implementation Instructions](task-implementation.instructions.md)

Systematic process for implementing comprehensive task plans and tracking progress.

- **Context**: Task plan execution, implementation tracking
- **Scope**: Plan analysis, progressive implementation, change documentation
- **Apply When**: Following implementation plans from `.copilot-tracking/plans/`

### [Terraform Instructions](terraform.instructions.md)

Infrastructure as Code implementation guidance for HashiCorp Terraform development.

- **Context**: Multi-cloud infrastructure deployment, Terraform modules
- **Scope**: Terraform syntax, module design, provider configuration
- **Apply When**: Creating or modifying Terraform infrastructure code

## Usage Guidelines

### Adding Instructions to Context

1. Open GitHub Copilot Chat
2. Select **Add Context > Instructions**
3. Choose the relevant instruction file for your development context
4. Add additional context (files, folders) as needed
5. Provide your development prompt

### When to Apply Instructions

Instructions are automatically applied based on their `applyTo` scope when the context matches. Manually add instructions when:

- Working in specific technology contexts (Bicep, Terraform, C#)
- Following systematic implementation processes
- Ensuring consistency with project standards
- Maintaining code quality and conventions

### Best Practices

- **Single Context**: Use one primary instruction file per conversation for focus
- **Relevant Scope**: Choose instructions that match your current development task
- **Combined Context**: Add project files and folders alongside instructions
- **Progressive Application**: Apply task implementation instructions for complex work

## Related Resources

- **[Chat Modes](../chatmodes/README.md)**: Specialized AI coaching and workflow assistance
- **[Prompts](../prompts/README.md)**: Reusable prompts for specific development tasks
- **[AI-Assisted Engineering Guide](../../docs/contributing/ai-assisted-engineering.md)**: Comprehensive AI assistance documentation

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
