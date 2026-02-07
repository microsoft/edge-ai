---
title: Azure DevOps Automation Katas
description: Learn Azure DevOps automation using agents, prompts, and instructions for work item management and CI/CD workflows
author: Edge AI Team
ms.date: 2025-10-14
ms.topic: kata-category
estimated_reading_time: 5
difficulty: intermediate
duration: 40-90 minutes
# Learning Platform Integration
category: ado-automation
prerequisite_katas: []
role_relevance:
  - devops-engineer
  - developer
  - project-manager
  - product-manager
target_audience:
  - DevOps Engineers
  - Software Developers
  - Project Managers
  - Product Managers
  - Technical Leads
learning_objectives:
  - Develop expertise in Azure DevOps agent activation and prompt-driven work item automation
  - Apply instruction files for systematic work item discovery and planning workflows
  - Develop expertise in pull request automation and build pipeline integration
  - Build effective Azure DevOps automation workflows using MCP tool patterns
# Content Classification
content_type: hands-on
real_world_application: Real-world Azure DevOps automation scenarios for work item management, pull requests, and CI/CD integration
complexity_factors:
  - MCP server configuration and authentication
  - Understanding agent activation and context switching patterns
  - Balancing automated workflows with manual oversight and validation
  - Integrating multiple instruction files for complex multi-phase operations
# Repository Integration
uses_prompts:
  - .github/prompts/ado-wit-discovery.prompt.md
  - .github/prompts/ado-update-wit-items.prompt.md
  - .github/prompts/ado-get-build-info.prompt.md
  - .github/prompts/ado-create-pull-request.prompt.md
uses_instructions:
  - .github/instructions/ado-wit-discovery.instructions.md
  - .github/instructions/ado-wit-planning.instructions.md
  - .github/instructions/ado-update-wit-items.instructions.md
  - .github/instructions/ado-get-build-info.instructions.md
  - .github/instructions/ado-create-pull-request.instructions.md
uses_agents:
  - .github/agents/ado-prd-to-wit.agent.md
repository_paths:
  - .github/prompts/ado-*.md
  - .github/instructions/ado-*.md
  - .github/agents/ado-*.md
repository_integration:
  - ".github/prompts/ado-*.md"
  - ".github/instructions/ado-*.md"
  - ".github/agents/ado-*.md"
# Success Criteria & Assessment
success_criteria:
  - Demonstrate effective agent usage for Azure DevOps automation
  - Apply systematic instruction file workflows for work item management
  - Execute end-to-end pull request and build automation workflows
  - Integrate MCP tools effectively for Azure DevOps operations
common_pitfalls:
  - "MCP server not configured": Complete Kata 01 before attempting other katas
  - "Authentication failures": Verify PAT token has correct scopes and hasn't expired
  - "Incorrect agent selection": Review agent descriptions and tool availability before activation
  - "Skipping instruction file steps": Follow all phases in instruction files sequentially
  - "Manual work item creation": Leverage MCP tools for automated work item operations
  - "Incomplete work item linking": Ensure proper parent-child and related work item relationships
# SEO & Discoverability
keywords:
  - azure-devops
  - ado
  - agent
  - automation
  - work-items
  - mcp-tools
  - pull-requests
  - ci-cd
tags:
  - azure-devops
  - automation
  - agents
  - work-items
  - ci-cd
# AI Coaching Integration
ai_coaching_enabled: true
validation_checkpoints:
  - "Agent activation: Verify correct agent selected with appropriate tool access"
  - "Instruction compliance: Confirm all phases and steps from instruction files completed"
  - "Work item validation: Ensure proper hierarchy, linking, and field population"
  - "Automation workflow: Validate end-to-end automation from discovery to deployment"
extension_challenges:
  - challenge_name: Multi-Repository Work Item Coordination
    description: Automate work item creation and linking across multiple repositories with coordinated pull requests
    difficulty: advanced
    estimated_time: 75 minutes
  - challenge_name: Custom Build Pipeline Integration
    description: Create custom agent and instructions for specialized build pipeline automation workflows
    difficulty: expert
    estimated_time: 90 minutes
troubleshooting_guide: |
  **Common Issues:**
  - MCP tool not available: Verify agent includes required MCP tool in tools list
  - Instruction file phase errors: Re-read instruction file and ensure all prerequisites met
  - Work item creation failures: Check Azure DevOps permissions and project configuration
  - Build status retrieval issues: Verify build ID or branch name and pipeline configuration
---

## Quick Context

Azure DevOps Automation katas provide hands-on practice with the edge-ai repository's Azure DevOps agents, prompts, and instruction files. These exercises teach you how to leverage specialized AI assistants (agents) and structured workflows (instruction files) to automate work item management, pull request creation, and CI/CD integration using MCP (Model Context Protocol) tools.

📊 **[Track Your Progress](../../catalog.md)** - Monitor your progress on your learning journey

## 🤖 AI Coaching Available

This kata category includes AI coaching support to help guide you through:

- Understanding and activating Azure DevOps-specific agents
- Following instruction file workflows for systematic automation
- Using MCP tools for Azure DevOps work item and pipeline operations
- Troubleshooting common automation and integration challenges

## Learning Objectives

By completing these Azure DevOps Automation katas, you will:

- **MCP Server Configuration**: Set up and validate Azure DevOps MCP server connection with PAT authentication
- **Agent Proficiency**: Understand how to select and activate specialized agents for Azure DevOps tasks
- **Work Item Operations**: Learn to search, create, and link work items using MCP tools
- **Instruction File Workflows**: Follow multi-phase instruction files for systematic automation workflows
- **Pull Request Automation**: Automate PR creation with work item linking and reviewer assignment
- **CI/CD Integration**: Monitor builds and automatically update work item status based on pipeline results
- **Feature Planning**: Plan and execute small feature implementations with proper work item hierarchies

## Azure DevOps Automation Katas

This kata category focuses on building expertise with the Azure DevOps automation capabilities built into the edge-ai repository. You'll learn how to leverage specialized agents (context-aware AI assistants), prompts (reusable automation templates), and instruction files (structured workflow guides) to automate common DevOps tasks like work item creation, pull request management, and build monitoring.

### What You'll Practice

- **Agent Activation**: Select and activate the appropriate agent for Azure DevOps tasks (e.g., `ado-prd-to-wit` for work item planning)
- **Instruction File Navigation**: Follow structured, multi-phase instruction files that ensure consistent and complete automation workflows
- **MCP Tool Usage**: Execute Azure DevOps operations using MCP tools for work items, repositories, pipelines, and wikis
- **Workflow Integration**: Connect multiple automation phases from discovery to planning to execution and validation

### Project Integration Resources

These katas integrate directly with the Azure DevOps automation resources in the edge-ai repository:

- **Agents** (`.github/agents/`): Specialized AI assistants pre-configured with Azure DevOps MCP tools and domain expertise
- **Prompts** (`.github/prompts/`): Reusable prompt templates for common Azure DevOps automation scenarios
- **Instructions** (`.github/instructions/`): Structured workflow guides defining multi-phase automation processes

<!-- AUTO-GENERATED:START -->
<!-- This section is automatically generated. Manual edits will be overwritten. -->

## Streamlined Kata Progression

| #   | Kata Title                                                                            | Difficulty   | Duration | Prerequisites | Technology Focus                                           | Scaffolding  |
|-----|---------------------------------------------------------------------------------------|--------------|----------|---------------|------------------------------------------------------------|--------------|
| 100 | [100 - Configure Azure DevOps MCP Server](./100-configure-mcp-server.md)              | ⭐ Foundation | 15 min   | —             | Azure DevOps, MCP (Model Context Protocol), GitHub Copilot | Heavy        |
| 100 | [100 - Discover Single Work Item](./100-single-work-item-discovery.md)                | ⭐ Foundation | 23 min   | → 100         | Azure DevOps, MCP, Work Items                              | Heavy        |
| 200 | [200 - Create Single Task](./200-create-single-task.md)                               | ⭐⭐ Skill     | 25 min   | → 100         | Azure DevOps, MCP, Work Items                              | Heavy        |
| 200 | [200 - Create User Story with Tasks](./200-create-user-story-with-tasks.md)           | ⭐⭐ Skill     | 30 min   | → 200         | Azure DevOps, MCP, Work Items                              | Medium-Heavy |
| 300 | [300 - Link Work Items to Pull Request](./300-link-work-items-to-pull-request.md)     | ⭐⭐⭐ Advanced | 30 min   | → 200         | Azure DevOps, MCP, Work Items                              | Medium-Heavy |
| 300 | [300 - Monitor Build and Update Work Items](./300-monitor-build-update-work-items.md) | ⭐⭐⭐ Advanced | 35 min   | → 300         | Azure DevOps, MCP, Work Items                              | Light        |
| 300 | [300 - Small Feature Planning](./300-small-feature-planning.md)                       | ⭐⭐⭐ Advanced | 40 min   | → 200         | Azure DevOps, MCP, Work Items                              | Light        |

<!-- AUTO-GENERATED:END -->

### Learning Progression

<!-- AUTO-GENERATED: Learning Progression START -->

### 100 - Foundation Level

- **Focus**: Learn to configure the Azure DevOps Model Context Protocol server for GitHub Copilot integration with PAT token authentication and connection verification and Learn to query and discover individual Azure DevOps work items using MCP commands with ID-based lookup and title search patterns
- **Skills**: Azure DevOps, MCP (Model Context Protocol), GitHub Copilot, Azure CLI, MCP
- **Time-to-Practice**: Under 1 hour

### 200 - Skill Level

- **Focus**: Learn to create individual Azure DevOps task work items using MCP automation with proper field population and validation and Learn to create hierarchical Azure DevOps work items with parent-child relationships using MCP automation for user story decomposition
- **Skills**: Azure DevOps, MCP, Work Items, Task Creation, GitHub Copilot
- **Time-to-Practice**: Under 1 hour

### 300 - Advanced Level

- **Focus**: Learn to associate Azure DevOps work items with pull requests using MCP automation for integrated development workflows and Learn to track Azure DevOps pipeline builds and automatically update work items based on build status using MCP automation
- **Skills**: Azure DevOps, MCP, Work Items, Pull Requests, Git
- **Time-to-Practice**: 1-2 hours

<!-- AUTO-GENERATED: Learning Progression END -->

## Real-World Application

These streamlined katas prepare you for:

- **Rapid Work Item Creation**: Automate creation of 50+ work items from Product Requirements Documents (PRDs) in minutes instead of hours
- **Consistent PR Workflows**: Ensure every pull request follows project standards with automatic work item linking, reviewer assignment, and description generation
- **Build Pipeline Integration**: Monitor build status, automatically update work items, and trigger deployment workflows based on build results
- **Cross-Repository Coordination**: Manage work items spanning multiple repositories with coordinated pull requests and synchronized deployments

## Prerequisites

### Required

- **Azure DevOps Access**: Account with access to an Azure DevOps organization and project
- **Development Environment**: VS Code with GitHub Copilot or equivalent AI assistant with MCP support
- **Permissions**: Work Items (Read & Write) permissions in your Azure DevOps project

### Helpful (Not Required)

- Basic understanding of Azure DevOps work item types (Epic, Feature, User Story, Task)
- Familiarity with Git workflows (branches, pull requests)
- Experience with CI/CD pipelines (for advanced katas)

### Before Starting

Complete **[Kata 01 - Configure Azure DevOps MCP Server][kata-01]** before attempting any other katas in this category. This 15-minute setup ensures your MCP server is properly configured and authenticated.

**Ready to start Azure DevOps automation practice?**

🚀 **[Begin with 01 - Configure Azure DevOps MCP Server][kata-01]**

*Excel at Azure DevOps automation by learning to leverage the powerful agent and instruction file ecosystem built into the edge-ai repository.*

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
<!-- Internal Project Links -->
[kata-01]: /learning/katas/ado-automation/100-configure-mcp-server
