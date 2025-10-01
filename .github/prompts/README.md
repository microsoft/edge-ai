---
title: GitHub Copilot Prompts
description: Coaching and guidance prompts for specific development tasks that provide step-by-step assistance and context-aware support
author: Edge AI Team
ms.date: 08/22/2025
ms.topic: hub-page
estimated_reading_time: 3
keywords:
  - github copilot
  - prompts
  - ai assistance
  - coaching
  - guidance
  - development workflows
---

## GitHub Copilot Prompts

This directory contains **coaching and guidance prompts** designed to provide step-by-step assistance for specific development tasks. Unlike instructions that focus on systematic implementation, prompts offer educational guidance and context-aware coaching to help you learn and apply best practices. Prompts are organized by workflow focus areas: onboarding & planning, implementation & delivery, process & documentation, work tracking, and prompt engineering.

## How to Use Prompts

Prompts can be invoked in GitHub Copilot Chat using `/prompt-name` syntax (e.g., `/getting-started`, `/deploy`). They provide:

- **Educational Guidance**: Step-by-step coaching approach
- **Context-Aware Assistance**: Project-specific guidance and examples
- **Best Practices**: Established patterns and conventions
- **Interactive Support**: Conversational assistance for complex tasks

## Available Prompts

### Onboarding & Planning

- **[Getting Started](./getting-started.prompt.md)** - Project onboarding and initial setup guidance
- **[Project Planning](./edge-ai-project-planning.prompt.md)** - Edge AI project planning guidance

### Implementation & Delivery

- **[Deploy](./deploy.prompt.md)** - Deployment workflows and best practices
- **[Terraform from Blueprint](./terraform-from-blueprint.prompt.md)** - Converting blueprints to Terraform
- **[Terraform Variable Consistency Manager](./tf-variable-consistency-manager.prompt.md)** - Terraform variable standardization and consistency management
- **[IoT Operations Version Upgrade](./iotops-version-upgrade.prompt.md)** - Azure IoT Operations component upgrade workflow and implementation

### Source Control & Commit Quality

- **[Commit (Stage + Commit)](./commit.prompt.md)** - Stages all changes and creates a Conventional Commit automatically
- **[Generate Commit Message](./gen-commit-message.prompt.md)** - Generates a compliant commit message for currently staged changes
- **[Git Setup](./git-setup.prompt.md)** - Verification-first Git configuration assistant

### Work Tracking & Summarization

- **[Get My Work Items](./get-my-work-items.prompt.md)** - Retrieves ordered @Me Azure DevOps work items and exports raw JSON
- **[Summarize My Work Items](./summarize-my-work-items.prompt.md)** - Resumable enrichment + summary with repo context & handoff payloads

### Documentation & Process

- **[ADR Creation](./adr-create.prompt.md)** - Architecture Decision Record creation guidance *(Migrated to [ADR Creation Chatmode](../chatmodes/adr-creation.chatmode.md) for enhanced capabilities)*
- **[Pull Request](./pull-request.prompt.md)** - PR description and review assistance

### Prompt Engineering

- **[Prompt Creation](./prompt-new.prompt.md)** - Creating new prompt files systematically
- **[Prompt Refactor](./prompt-refactor.prompt.md)** - Optimizing and improving existing prompts

## Prompts vs Instructions vs Chat Modes

- **Prompts** (this directory): Coaching and educational guidance for learning
- **[Instructions](../instructions/README.md)**: Systematic implementation and automation
- **[Chat Modes](../chatmodes/README.md)**: Specialized AI assistance with enhanced capabilities

## Quick Start

1. **New to the project?** Start with [Getting Started](./getting-started.prompt.md)
2. **Planning scope or roadmap?** Use [Project Planning](./edge-ai-project-planning.prompt.md)
3. **Need deployment help?** Try [Deploy](./deploy.prompt.md)
4. **Working on infra translation?** Use [Terraform from Blueprint](./terraform-from-blueprint.prompt.md)
5. **Committing changes?** Use [Generate Commit Message](./gen-commit-message.prompt.md) or [Commit](./commit.prompt.md)
6. **Tracking your work?** Run [Get My Work Items](./get-my-work-items.prompt.md) then [Summarize My Work Items](./summarize-my-work-items.prompt.md)
7. **Creating documentation?** Use [ADR Creation](./adr-create.prompt.md) or [Pull Request](./pull-request.prompt.md)

## Related Resources

- **[AI-Assisted Engineering Guide](../../docs/contributing/ai-assisted-engineering.md)** - Complete guide to project AI resources
- **[Core Guidance](../../copilot/)** - Comprehensive guidance files for development standards

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
