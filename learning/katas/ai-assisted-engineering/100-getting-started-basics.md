---
title: 'Kata: 100 - Getting Started Basics'
description: Learn AI-assisted project onboarding and first deployment using the getting-started prompt to deploy your first Edge AI blueprint
author: Edge AI Team
ms.date: 2025-01-20
kata_id: ai-assisted-engineering-100-getting-started-basics
kata_category:
  - ai-assisted-engineering
kata_difficulty: 1
estimated_time_minutes: 45
learning_objectives:
  - Learn AI-assisted project onboarding and first deployment
  - Learn the getting-started prompt for guided deployment
  - Practice interactive deployment workflows with Azure setup
  - Handle deployment challenges using structured AI assistance
prerequisite_katas:
  - ai-assisted-engineering-100-ai-development-fundamentals
technologies:
  - GitHub Copilot
  - Azure
  - Terraform
success_criteria:
  - Use getting-started prompt for guided first deployment of Edge AI blueprints
  - Practice interactive deployment workflows with Azure setup and parameter configuration
  - Handle deployment challenges using structured AI assistance and error handling
  - Build confidence with real deployment experience through coached practice
ai_coaching_level: guided
scaffolding_level: heavy
hint_strategy: progressive
common_pitfalls: []
requires_azure_subscription: false
requires_local_environment: true
tags:
  - ai-assisted-engineering
search_keywords:
  - ai-assisted-onboarding
  - first-deployment
  - getting-started-prompt
  - guided-deployment
  - azure-setup
---

## Quick Context

**You'll Learn**: Develop AI-enhanced workflows and documentation strategies for infrastructure management using GitHub Copilot's capabilities.

**Real Challenge**: Your team needs to standardize Azure deployment documentation and workflows, but manual approaches are time-consuming and inconsistent. Learn to leverage AI assistance for consistent, high-quality infrastructure documentation.

## Essential Setup

**Required** (check these first):

- [ ] VS Code with GitHub Copilot extension installed and active subscription
- [ ] Completion of AI Development Fundamentals kata (ai-assisted-engineering-01) for foundational AI-assisted workflows
- [ ] Azure CLI and Terraform installed and configured (`az --version && terraform --version` to verify)
- [ ] Azure CLI basics (az login, az account list/set commands) and Terraform basics (init, plan, apply workflow)
- [ ] Understanding of Azure organization (subscriptions, resource groups, regions) and deployment workflow expectations (interactive guidance, one question at a time, error troubleshooting)
- [ ] Time allocated: 45 minutes for guided first deployment with Azure setup

**Quick Validation**: Verify tools with `az --version && terraform --version`, confirm Copilot extension shows "Ready" in status bar.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on 02 - Getting Started Basics kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Getting-Started Deployment Initiation (15 minutes)

**What You'll Do**: Use the getting-started prompt to begin your first Edge AI deployment

**Resource Context**: Before starting, review the **[Prompts Overview][project-prompts]** to understand how the getting-started prompt guides you through deployment workflows.

**Steps**:

1. **Initiate** deployment guidance
   - [ ] Open GitHub Copilot Chat and reference the getting-started prompt
   - [ ] Try: *"I'm new to this project and want to deploy my first Edge AI solution. Can you guide me through the process?"*
   - [ ] Follow the interactive guidance provided (one question at a time)
   - [ ] **Expected result**: Clear understanding of deployment approach and next steps

2. **Complete** Azure setup
   - [ ] Follow AI guidance for Azure login and subscription selection
   - [ ] Answer questions about tenant and subscription preferences
   - [ ] Validate Azure connectivity and access
   - [ ] **Expected result**: Azure environment properly configured for deployment

3. **Understand** the deployment target
   - [ ] Learn about the full-single-node-cluster blueprint through AI explanation
   - [ ] Ask: *"What will this deployment create and why is this a good starting point?"*
   - [ ] **Success check**: Clear understanding of what you're about to deploy and its purpose

### Task 2: Interactive Parameter Configuration (10 minutes)

**What You'll Do**: Configure deployment parameters using AI-assisted guidance

**Steps**:

1. **Configure** deployment parameters
   - [ ] Follow AI guidance to set deployment parameters (location, naming, etc.)
   - [ ] Use the checklist approach for parameter configuration
   - [ ] Ask questions about parameters you don't understand
   - [ ] **Expected result**: Properly configured deployment parameters

2. **Validate** configuration choices
   - [ ] Review the complete parameter configuration with AI assistance
   - [ ] Ask: *"Can you explain why these parameter choices make sense for my first deployment?"*
   - [ ] Make any needed adjustments based on your specific needs
   - [ ] **Expected result**: Confident understanding of your deployment configuration

3. **Prepare** for deployment execution
   - [ ] Confirm final configuration with AI guidance
   - [ ] Understand what the deployment process will do
   - [ ] **Success criteria**: Ready to execute deployment with clear expectations

### Task 3: Deployment Execution and Validation (15 minutes)

**What You'll Do**: Execute the deployment and validate success using AI assistance

**Steps**:

1. **Execute** the deployment
   - [ ] Follow AI guidance to start the deployment process
   - [ ] Monitor deployment progress with AI assistance for any issues
   - [ ] Use error handling if any problems arise during deployment
   - [ ] **Expected result**: Successful deployment completion

2. **Validate** deployment success
   - [ ] Use AI assistance to verify that all components deployed correctly
   - [ ] Ask: *"How can I validate that my deployment was successful and what should I see in Azure?"*
   - [ ] Explore the deployed resources with AI guidance
   - [ ] **Expected result**: Confirmed successful deployment with understanding of deployed components

3. **Plan** next steps and cleanup
   - [ ] Use AI guidance to understand cleanup procedures
   - [ ] Learn about next development steps now that you have a working deployment
   - Practice cleanup process (or plan it for later)
   - **Success criteria**: Complete deployment experience with clear next steps and cleanup knowledge

## Completion Check

You have successfully completed this kata when you can demonstrate:

- **Guided Deployment Proficiency**: Successfully use getting-started prompt for guided first deployment of Edge AI blueprints
- **Interactive Workflow Proficiency**: Practice interactive deployment workflows with Azure setup and parameter configuration
- **Deployment Challenge Resolution**: Handle deployment challenges using structured AI assistance and error handling
- **Deployment Confidence Building**: Build confidence with real deployment experience through coached practice

---

## Reference Appendix

### Help Resources

- [Getting Started Prompt][getting-started-prompt] - Interactive deployment guidance
- [Full Single Node Cluster Blueprint][blueprint-single-node] - Your first deployment target
- [Azure Prerequisites][azure-prerequisites] - Azure setup requirements
- [Deployment Overview][deployment-overview] - Understanding Edge AI deployments

### Professional Tips

- **Start Small**: The full-single-node-cluster blueprint is the recommended first deployment for learning
- **Document Everything**: Keep notes about your deployment choices and learnings for future reference
- **Ask Questions**: Use AI assistance liberally to understand each deployment step and configuration choice
- **Validate Incrementally**: Check each deployment phase before moving to the next step

### Troubleshooting

**Issue**: Azure login or subscription issues
**Solution**: Ensure you have active Azure access and proper permissions; use `az login` and `az account list` to verify

**Issue**: Deployment parameter confusion
**Solution**: Ask AI to explain each parameter's purpose and impact before setting values

**Issue**: Deployment failures
**Solution**: Use AI assistance to interpret error messages and follow suggested remediation steps; check Azure portal for detailed error information

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
[getting-started-prompt]: /.github/prompts/getting-started.prompt.md
[project-prompts]: /.github/prompts/
[blueprint-single-node]: /blueprints/full-single-node-cluster/
[azure-prerequisites]: /README.md#getting-started-and-prerequisites-setup
[deployment-overview]: /docs/getting-started/
