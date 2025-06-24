---
title: 01 - Deployment Basics
description: Learn AI-assisted deployment workflows using the deploy prompt to accelerate blueprint and component deployment with systematic planning, execution, and troubleshooting
author: Edge AI Team
ms.date: 2025-06-17
ms.topic: kata
estimated_reading_time: 8
difficulty: beginner
duration: 60-90 minutes
keywords:
  - praxisworx
  - edge deployment
  - deployment basics
  - blueprint deployment
  - infrastructure as code
  - terraform
  - bicep
  - troubleshooting
  - kata coach
  - mode transitions
  - numbered progression
---

## Quick Context

**You'll Learn**: Master AI-assisted deployment workflows using structured deployment guidance for reliable infrastructure deployment and troubleshooting.

**Real Challenge**: Your edge infrastructure deployment failed mid-process, leaving resources in an inconsistent state. You need to rapidly assess the situation, plan recovery steps, and complete the deployment while documenting the issue for future prevention.

**Your Task**: Use AI-assisted deployment workflows to successfully deploy a blueprint or component, handle any deployment issues that arise, and validate the deployment meets requirements.

## 🤖 AI Coaching Available - Get Interactive Help

> **🚀 Supercharge Your Learning with AI Coaching**
>
> **New to AI-assisted learning? Want task check-offs, progress tracking, and personalized guidance?**
>
> Load our specialized **PraxisWorx Kata Coach** for:
>
> - ✅ **Task Check-offs**: Mark completed tasks and track your progress
> - 🎯 **Learning Evaluation**: Reflect on your progress with guided questions
> - 🆘 **Coaching & Troubleshooting**: Get progressive hints when you're stuck
> - 🔄 **Session Resumption**: Pick up exactly where you left off
> - 🧭 **Smart Guidance**: Personalized coaching based on your progress patterns

### How to Load Your AI Coach

**Step 1**: In GitHub Copilot Chat, select the **PraxisWorx Kata Coach** mode from the chat mode selector.

**Step 2**: Send this starter message to begin your coached session:

```text
I'm working on Deployment Basics kata and want interactive coaching with progress tracking and learning evaluation.
```

**💡 Pro Tip**: Your coach can see your checkbox progress when you're using the local docs (`npm run docs:training`) and help you manage it!

### Essential Setup

**Required** (check these first):

- [ ] Completion of AI Development Fundamentals and Getting Started Basics katas
- [ ] Azure CLI configured and authenticated
- [ ] Access to project blueprints and components for deployment practice
- [ ] GitHub Copilot Chat enabled

**Quick Validation**: Can run `az account show` and see your authenticated Azure subscription details.

## Practice Tasks

### Task 1: Deployment Planning and Preparation (15 minutes)

**What You'll Do**: Plan a deployment using AI assistance to analyze requirements, validate prerequisites, and create execution strategy.

**Steps**:

1. **Select** a blueprint for deployment practice
   - [ ] Choose from available blueprints in `blueprints/`
   - [ ] Review README.md to understand deployment requirements and dependencies
   - **Expected result**: Clear understanding of what will be deployed and requirements

2. **Use** AI assistance for deployment planning
   - [ ] Use GitHub Copilot Chat with deploy-focused prompts to analyze deployment steps
   - [ ] Ask for prerequisite validation, potential issues, and mitigation strategies
   - **Expected result**: Markdown document with a comprehensive deployment plan and risk assessment

3. **Validate** deployment prerequisites and environment readiness
   - [ ] Verify Azure subscription permissions and resource provider availability
   - [ ] Check for required tools, configurations, and dependencies
   - **Success check**: All prerequisites confirmed and deployment environment ready

### Task 2: AI-Assisted Deployment Execution (35 minutes)

**What You'll Do**: Execute the deployment using systematic AI guidance while monitoring progress and handling any issues.

**Steps**:

1. **Execute** deployment with AI monitoring and guidance
   - [ ] Start deployment process using project deployment scripts or commands
   - [ ] Use Copilot Chat to monitor progress and interpret output
   - [ ] Apply AI recommendations for optimization and issue prevention
   - **Expected result**: Deployment progressing with active AI assistance and monitoring

2. **Handle** any deployment issues with structured troubleshooting
   - [ ] If issues arise, use AI assistance to diagnose problems quickly
   - [ ] Apply systematic troubleshooting approach with AI guidance
   - [ ] Use a scratch markdown document ro record issues and resolutions for future reference
   - **Expected result**: Any deployment problems resolved efficiently with AI support

3. **Validate** deployment success and functionality
   - [ ] Use AI assistance to verify deployment completed successfully
   - [ ] Test deployed resources meet functional requirements
   - [ ] Document deployment results and any lessons learned
   - **Success criteria**: Deployment successful with validated functionality and documented outcomes

### Task 3: Advanced Troubleshooting and Recovery Practice (15 minutes)

**What You'll Do**: Practice advanced deployment troubleshooting scenarios and recovery procedures using AI assistance.

**Steps**:

1. **Simulate** or encounter a deployment challenge, consider unregistering a critical azure resource provider
   - [ ] Either work with a real deployment issue or create a practice scenario
   - [ ] Use AI assistance to systematically diagnose the problem
   - [ ] Apply structured troubleshooting methodology with AI guidance
   - **Expected result**: Clear understanding of the issue and potential solutions

2. **Implement** recovery procedures with AI optimization
   - [ ] Use AI assistance to plan and execute recovery steps
   - [ ] Apply best practices for minimizing downtime and preventing data loss
   - [ ] Validate recovery success and system stability
   - **Expected result**: Successful recovery with improved system resilience

3. **Document** troubleshooting process and preventive measures
   - [ ] Create documentation of the issue, resolution, and prevention strategies
   - [ ] Use AI assistance to improve documentation quality and completeness
   - **Success criteria**: Comprehensive troubleshooting documentation ready for team use

## Completion Check

**You've Succeeded When**:

- [ ] Successfully planned and executed a deployment using AI-assisted workflows
- [ ] Demonstrated effective use of AI assistance for troubleshooting and issue resolution
- [ ] Created documentation of deployment process and any issues encountered
- [ ] Validated deployment meets functional requirements and quality standards

## Next Steps

**Continue Learning**: Practice with more complex edge deployment scenarios and advanced troubleshooting techniques

**Apply Skills**: Use this AI-assisted deployment workflow for real edge computing projects and production deployments

## Resources

- [PraxisWorx Kata Coach][kata-coach] - Step-by-step help and troubleshooting guidance
- [Deploy Prompt][deploy-prompt] - Structured deployment guidance for systematic workflows
- [Azure CLI Documentation][azure-cli] - Command help and deployment examples
- [Project Blueprints][project-blueprints] - Reference blueprint README files for deployment-specific guidance

---

<!-- Reference Links -->
[kata-coach]: /.github/chatmodes/praxisworx-kata-coach.chatmode.md
[deploy-prompt]: /.github/prompts/deploy.prompt.md
[project-blueprints]: /blueprints/README
[azure-cli]: https://docs.microsoft.com/en-us/cli/azure/

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
