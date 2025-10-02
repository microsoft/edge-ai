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
- **[Task Planner](./task-planner-plan.prompt.md)** - Creates implementation plans from research documents

### Implementation & Delivery

- **[Deploy](./deploy.prompt.md)** - Deployment workflows and best practices
- **[Terraform from Blueprint](./terraform-from-blueprint.prompt.md)** - Converting blueprints to Terraform
- **[Terraform Variable Consistency Manager](./tf-variable-consistency-manager.prompt.md)** - Terraform variable standardization and consistency management
- **[IoT Operations Version Upgrade](./iotops-version-upgrade.prompt.md)** - Azure IoT Operations component upgrade workflow and implementation

### Source Control & Commit Quality

- **[Git Commit (Stage + Commit)](./git-commit.prompt.md)** - Stages all changes and creates a Conventional Commit automatically
- **[Git Commit Message Generator](./git-commit-message.prompt.md)** - Generates a compliant commit message for currently staged changes
- **[Git Merge](./git-merge.prompt.md)** - Git merge, rebase, and rebase --onto workflows with conflict handling
- **[Git Setup](./git-setup.prompt.md)** - Verification-first Git configuration assistant

### Azure DevOps Integration

- **[ADO Create Pull Request](./ado-create-pull-request.prompt.md)** - Creates Azure DevOps PRs with work item discovery and reviewer identification
- **[ADO Get Build Info](./ado-get-build-info.prompt.md)** - Retrieves Azure DevOps build information for PRs or specific builds
- **[ADO Work Item Discovery](./ado-wit-discovery.prompt.md)** - Discovers and plans Azure DevOps User Stories and Bugs from research or changes
- **[ADO Update Work Items](./ado-update-wit-items.prompt.md)** - Updates work items based on planning files
- **[Get My Work Items](./get-my-work-items.prompt.md)** - Retrieves ordered @Me Azure DevOps work items and exports raw JSON
- **[Create Work Items Handoff](./create-my-work-items-handoff.prompt.md)** - Generates comprehensive work item handoff markdown with repo context enrichment

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
3. **Creating implementation plans?** Try [Task Planner](./task-planner-plan.prompt.md)
4. **Need deployment help?** Use [Deploy](./deploy.prompt.md)
5. **Working on infra translation?** Use [Terraform from Blueprint](./terraform-from-blueprint.prompt.md)
6. **Committing changes?** Use [Git Commit Message Generator](./git-commit-message.prompt.md) or [Git Commit](./git-commit.prompt.md)
7. **Handling merge conflicts?** Use [Git Merge](./git-merge.prompt.md)
8. **Tracking your work?** Run [Get My Work Items](./get-my-work-items.prompt.md) then [Create Work Items Handoff](./create-my-work-items-handoff.prompt.md)
9. **Creating Azure DevOps PRs?** Use [ADO Create Pull Request](./ado-create-pull-request.prompt.md)
10. **Checking build status?** Use [ADO Get Build Info](./ado-get-build-info.prompt.md)
11. **Creating documentation?** Use [ADR Creation](./adr-create.prompt.md) or [Pull Request](./pull-request.prompt.md)

## Related Resources

- **[AI-Assisted Engineering Guide](../../docs/contributing/ai-assisted-engineering.md)** - Complete guide to project AI resources
- **[Core Guidance](../../copilot/)** - Comprehensive guidance files for development standards

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
