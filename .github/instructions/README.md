---
title: GitHub Copilot Instructions
description: Context-specific development instructions for systematic AI-assisted implementation
author: Edge AI Team
ms.date: 2026-05-15
ms.topic: reference
estimated_reading_time: 3
keywords:
  - github copilot
  - instructions
  - development standards
  - ai assistance
  - context-specific guidance
---

This directory contains Edge AI-specific instruction files designed to be used with GitHub Copilot's "Add Context > Instructions" feature for systematic AI-assisted development.

## Overview

Instructions provide focused guidance for repository-specific development contexts and workflows. Shared language, documentation, commit message, and infrastructure coding standards are provided by the [hve-core](https://github.com/microsoft/hve-core) VS Code extension.

## Available Instructions

> **Note:** Azure DevOps integration instructions (work item planning, discovery, pull request creation, build info, and work item updates) are now provided by the [hve-core](https://github.com/microsoft/hve-core) VS Code extension.

### Development Workflows

> **Note:** Git merge, rebase, branch operation, task implementation, task research, and task review workflows are now provided by the [hve-core](https://github.com/microsoft/hve-core) VS Code extension.

#### [Terraform Variable Consistency Manager Instructions](tf-variable-consistency-manager.instructions.md)

Required instructions for Terraform variable consistency including canonical definitions, requirements, and detailed instructions.

- **Context**: Terraform variable validation and standardization
- **Scope**: Variable naming, type definitions, validation rules, documentation
- **Apply When**: Working with `.copilot-tracking/chore/tf-variable-check.md`

#### [Build Documentation Instructions](build-documentation.instructions.md)

Required documentation standards for build and CI/CD content.

- **Context**: Build and CI/CD documentation authoring
- **Scope**: Troubleshooting sections, related documentation, frontmatter, heading hierarchy, and code examples
- **Apply When**: Working in `docs/build-cicd/**/*.md`

#### [CSS Instructions](css.instructions.md)

Required CSS architecture and implementation standards for the documentation site.

- **Context**: Edge AI documentation styling and theme implementation
- **Scope**: Modular CSS structure, design tokens, dark mode, specificity, responsive behavior, and validation
- **Apply When**: Working with `**/*.css`

#### [JavaScript Instructions](javascript.instructions.md)

Required JavaScript standards that load Edge AI-specific JavaScript guidance.

- **Context**: Repository JavaScript implementation
- **Scope**: Backend, frontend, and utility JavaScript conventions, testing expectations, performance, and CSS separation
- **Apply When**: Working with `**/*.js`

### Application Development

#### [Application Instructions](application.instructions.md)

Instructions for creating, importing, and managing edge applications.

- **Context**: Edge application development and deployment
- **Scope**: Application structure, deployment patterns, edge-specific requirements
- **Apply When**: Working in `**/src/500-application/**` pattern

#### [Rust Crate Registration Instructions](rust-crate-registration.instructions.md)

Required registration of Rust crates under `src/500-application` for CI test/coverage and Codecov reporting.

- **Context**: Rust workspace coverage, CI matrix, Codecov flag mapping
- **Scope**: `rust-tests.yml` matrix and triggers, `codecov.yml` flags and ignore lists, opt-out path
- **Apply When**: Adding, restructuring, or removing crates under `**/src/500-application/**/Cargo.toml`, or editing `**/.github/workflows/rust-tests.yml` or `**/codecov.yml`

#### [WASM Build Deploy Instructions](wasm-build-deploy.instructions.md)

Required build, deployment, and test standards for Rust-based WASM operators.

- **Context**: WASM operator build and deployment workflows
- **Scope**: Graph schemas, Terraform integration, naming conventions, and validation rules
- **Apply When**: Working in `**/src/500-application/**/operators/**`

#### [WASM Operator Templates Instructions](wasm-operator-templates.instructions.md)

Code templates for Rust-based WASM operator modules.

- **Context**: WASM operator creation and modification
- **Scope**: Cargo manifests, Map, Filter, Accumulate, ONNX, graph YAML, and Terraform configuration templates
- **Apply When**: Working in `**/src/500-application/**/operators/**`

#### [WASM SDK Reference Instructions](wasm-sdk-reference.instructions.md)

SDK reference guidance for Rust-based WASM operator types and integration patterns.

- **Context**: Azure IoT Operations dataflow graph operator implementation
- **Scope**: SDK types, integration patterns, operator behavior, and best practices
- **Apply When**: Working in `**/src/500-application/**/operators/**`

### Shared HVE Core Instructions

Use the [hve-core](https://github.com/microsoft/hve-core) VS Code extension for shared coding standards and workflow guidance, including Bash, Bicep, C#, commit messages, Markdown, Python scripting, Rust, Terraform, pull request creation, task implementation, task research, task review, Git merge/rebase, and Azure DevOps workflows.

## Usage Guidelines

### Automatic Application

Instructions are automatically discovered and applied by GitHub Copilot based on file patterns and contexts defined in each instruction file's frontmatter or metadata. The system uses pattern matching to determine which instructions are relevant:

- **File Patterns**: Instructions apply to specific file glob patterns (e.g., `**/*.tf`, `**/*.md`)
- **Directory Contexts**: Instructions apply to specific directory structures (e.g., `.copilot-tracking/workitems/**`)
- **Workflow Contexts**: Instructions apply during specific operations (e.g., pull request creation, work item planning)

### Manual Application

To manually add instructions to a Copilot conversation:

1. Open GitHub Copilot Chat
2. Select **Add Context > Instructions**
3. Choose the relevant instruction file for your development context
4. Add additional context (files, folders) as needed
5. Provide your development prompt

### When to Manually Apply Instructions

While instructions are automatically applied, you may want to manually add them when:

- Working across multiple technology contexts simultaneously
- Ensuring compliance with specific workflows or protocols
- Providing explicit context for complex multi-step operations
- Overriding or emphasizing specific standards

### Pattern Matching Examples

The instruction system uses sophisticated pattern matching to automatically apply relevant guidance:

| Working On                                            | Auto-Applied Instructions                                         |
|-------------------------------------------------------|-------------------------------------------------------------------|
| `src/000-cloud/010-security/terraform/main.tf`        | HVE Core Terraform instructions                                   |
| `blueprints/full-multi-node-cluster/bicep/main.bicep` | HVE Core Bicep instructions                                       |
| `scripts/deploy-infrastructure.py`                    | HVE Core Python scripting instructions                            |
| `src/500-application/501-rust-telemetry/README.md`    | HVE Core Markdown instructions and local Application instructions |

### Best Practices

- **Context Awareness**: Trust the automatic pattern matching to apply relevant instructions
- **Focused Work**: Instructions are designed to work together; multiple instructions may apply simultaneously
- **Progressive Application**: Task implementation and planning instructions guide multi-step workflows
- **Validation**: Instructions include validation steps and checklists to ensure compliance

## Related Resources

- **[Custom Agents](../agents/README.md)**: Specialized AI coaching and workflow assistance
- **[Prompts](../prompts/README.md)**: Reusable prompts for specific development tasks
- **[AI-Assisted Engineering Guide](../../docs/contributing/ai-assisted-engineering.md)**: Comprehensive AI assistance documentation

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
