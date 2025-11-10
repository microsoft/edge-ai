---
title: GitHub Copilot Core Guidance
description: Comprehensive guidance files for development standards, deployment practices, and AI-assisted engineering workflows
author: Edge AI Team
ms.date: 2025-06-18
ms.topic: reference
estimated_reading_time: 4
keywords:
  - github copilot
  - core guidance
  - development standards
  - deployment guidance
  - ai-assisted engineering
  - best practices
---

This directory contains comprehensive core guidance files that are referenced by the main GitHub Copilot instructions to ensure consistent development practices and standards across the project.

## Overview

Core guidance files provide detailed standards, best practices, and procedural guidance for key development areas. These files are automatically referenced by GitHub Copilot through the main copilot instructions to ensure consistent, high-quality assistance across all development workflows.

## Available Core Guidance

### [Deploy Guidance](deploy.md)

Comprehensive deployment guidance and best practices for blueprints and CI workflows.

- **Purpose**: Systematic deployment procedures for blueprints and component CI folders
- **Scope**: Terraform and Bicep deployment workflows, Azure setup, error handling
- **Coverage**: Blueprint deployment, component CI deployment, framework-specific procedures
- **Integration**: Referenced by main copilot instructions for deployment assistance

### [Getting Started Guidance](getting-started.md)

Getting started guidance and onboarding procedures for new contributors.

- **Purpose**: Structured onboarding and environment setup for new project contributors
- **Scope**: Interactive setup processes, environment validation, prerequisite verification
- **Coverage**: Dev container setup, Azure authentication, project familiarization
- **Integration**: Referenced for new contributor assistance and project orientation

### [Python Script Guidance](python-script.md)

Python scripting standards and conventions for project automation.

- **Purpose**: Standardized Python development practices and script organization
- **Scope**: Code structure, error handling, documentation standards, testing practices
- **Coverage**: Script development, automation workflows, Python best practices
- **Integration**: Applied automatically for Python-related development tasks

### [C# Testing Guidance](csharp-tests.md)

C# testing standards and practices for .NET applications.

- **Purpose**: Comprehensive testing standards for C# codebases
- **Scope**: Unit testing, integration testing, test organization, best practices
- **Coverage**: Testing frameworks, test structure, assertion patterns, mocking
- **Integration**: Referenced for C# test development and quality assurance

### Technology-Specific Guidance

#### [Terraform Standards](terraform/)

Comprehensive Terraform development guidance and infrastructure standards.

- **Purpose**: Infrastructure as Code standards for Terraform development
- **Scope**: Module design, resource organization, variable management, best practices
- **Coverage**: Terraform syntax, module structure, deployment patterns, conventions

#### [Bicep Standards](bicep/)

Azure Bicep development guidance and infrastructure deployment standards.

- **Purpose**: Infrastructure as Code standards for Azure Bicep development
- **Scope**: Template design, resource organization, parameter management, best practices
- **Coverage**: Bicep syntax, template structure, deployment patterns, Azure conventions

#### [C# Development Standards](csharp/)

C# development guidance and coding standards for .NET applications.

- **Purpose**: Development standards for C# application development
- **Scope**: Code structure, naming conventions, architectural patterns, best practices
- **Coverage**: C# syntax, project organization, dependency management, conventions

#### [JavaScript Development Standards](javascript/)

JavaScript development guidance and coding standards for frontend and backend applications.

- **Purpose**: Development standards for JavaScript/Node.js application development
- **Scope**: ES6+ syntax, module organization, modern testing frameworks, architectural patterns, best practices
- **Coverage**: JavaScript syntax, project structure, Vitest and Happy DOM testing conventions, frontend and backend patterns
- **Testing Standards**: Comprehensive testing guidance in [javascript-tests.md](javascript/javascript-tests.md) covering Vitest, Happy DOM, mocking, and test organization

#### [CSS Development Standards](css/)

CSS development guidance and styling standards for frontend applications.

- **Purpose**: Development standards for CSS, styling, and frontend appearance
- **Scope**: Modern CSS features, responsive design, component styling, accessibility, performance
- **Coverage**: CSS syntax, organization patterns, responsive design principles, accessibility standards

#### [Bash Development Standards](bash/)

Bash scripting guidance and shell automation standards.

- **Purpose**: Shell scripting standards for automation and CI/CD workflows
- **Scope**: Script structure, error handling, automation patterns, best practices
- **Coverage**: Bash syntax, script organization, testing patterns, shell conventions

## Usage Guidelines

### Automatic Integration

Core guidance files are automatically referenced by GitHub Copilot through the main copilot instructions (`.github/copilot-instructions.md`). When working in relevant contexts, these standards are automatically applied to ensure consistency.

### Manual Reference

While automatic integration handles most scenarios, you can manually reference specific guidance:

- Review relevant guidance files before starting major development work
- Reference specific sections for detailed implementation guidance
- Use as authoritative source for project standards and conventions

### Updating Guidance

When updating core guidance files:

- Ensure changes align with overall project architecture and standards
- Update related instruction files if scope or structure changes
- Validate that automatic integration continues to work correctly
- Document significant changes for team awareness

## Integration Architecture

Core guidance files integrate with the broader AI assistance ecosystem:

- **Main Copilot Instructions**: Automatically reference these files for context-aware assistance
- **Context Instructions**: Specific instruction files reference relevant core guidance
- **Prompts**: Reusable prompts leverage guidance for consistent coaching
- **Chat Modes**: Specialized assistance modes utilize guidance for expert-level support

## Related Resources

- **[Chat Modes](../.github/chatmodes/README.md)**: Specialized AI coaching and workflow assistance
- **[Instructions](../.github/instructions/README.md)**: Context-specific development instructions
- **[Prompts](../.github/prompts/README.md)**: Reusable prompts for specific development tasks
- **[AI-Assisted Engineering Guide](../docs/contributing/ai-assisted-engineering.md)**: Comprehensive AI assistance documentation

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
