---
title: GitHub Copilot Prompts
description: Coaching and guidance prompts for specific development tasks that provide step-by-step assistance and context-aware support
author: Edge AI Team
ms.date: 2026-02-08
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

> **Note:** General-purpose prompts (task planning, ADR creation, prompt engineering, work item handoff) are provided by [hve-core](https://github.com/microsoft/hve-core) and loaded automatically via `.vscode/settings.json`. This directory contains only edge-ai-specific prompts.

## How to Use Prompts

Prompts can be invoked in GitHub Copilot Chat using `/prompt-name` syntax (e.g., `/getting-started`, `/deploy`). They provide:

- **Educational Guidance**: Step-by-step coaching approach
- **Context-Aware Assistance**: Project-specific guidance and examples
- **Best Practices**: Established patterns and conventions
- **Interactive Support**: Conversational assistance for complex tasks

## Available Prompts

### Onboarding & Planning

- **[Beads Planner Implementation Planning](../../copilot/beads/prompts/bd-planner-plan.prompt.md)** - Beads-first implementation planner for Beads-exclusive workflows
- **[Getting Started](./getting-started.prompt.md)** - Project onboarding and initial setup guidance
- **[Project Planning](./edge-ai-project-planning.prompt.md)** - Edge AI project planning guidance

### Implementation & Delivery

- **[Deploy](./deploy.prompt.md)** - Deployment workflows and best practices
- **[Terraform from Blueprint](./terraform-from-blueprint.prompt.md)** - Converting blueprints to Terraform
- **[Terraform Variable Consistency Manager](./tf-variable-consistency-manager.prompt.md)** - Terraform variable standardization and consistency management
- **[IoT Operations Version Upgrade](./iotops-version-upgrade.prompt.md)** - Azure IoT Operations component upgrade workflow and implementation

### Azure DevOps Integration

- **[ADO Work Item Discovery](./ado-wit-discovery.prompt.md)** - Discovers and plans Azure DevOps User Stories and Bugs from research or changes

## Prompts vs Instructions vs Custom Agents

- **Prompts** (this directory): Coaching and educational guidance for learning
- **[Instructions](../instructions/README.md)**: Systematic implementation and automation
- **[Custom Agents](../agents/README.md)**: Specialized AI assistance with enhanced capabilities

## Quick Start

1. **New to the project?** Start with [Getting Started](./getting-started.prompt.md)
2. **Planning scope or roadmap?** Use [Project Planning](./edge-ai-project-planning.prompt.md)
3. **Need deployment help?** Use [Deploy](./deploy.prompt.md)
4. **Working on infra translation?** Use [Terraform from Blueprint](./terraform-from-blueprint.prompt.md)

## Related Resources

- **[AI-Assisted Engineering Guide](../../docs/contributing/ai-assisted-engineering.md)** - Complete guide to project AI resources
- **[Core Guidance](../../copilot/)** - Comprehensive guidance files for development standards

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
