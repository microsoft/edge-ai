---
title: 'Kata: 100 - Deployment Basics'
description: Develop AI-assisted deployment workflows using structured guidance to deploy edge infrastructure and handle deployment failures in production environments
author: Edge AI Team
ms.date: 2025-06-17
kata_id: edge-deployment-100-deployment-basics
kata_category:
  - edge-deployment
kata_difficulty: 1
estimated_time_minutes: 30
learning_objectives:
  - Develop AI-assisted deployment workflows using structured deployment guidance
  - Understand component relationships and deployment ordering in edge architectures
  - Practice deploying basic edge infrastructure components systematically
  - Develop proficiency with edge-specific deployment patterns and troubleshooting
prerequisite_katas: []
technologies:
  - Terraform
  - Azure
  - GitHub Copilot
success_criteria:
  - Successfully deploy blueprint using AI assistance with proper planning and validation
  - Resolve deployment issues with structured troubleshooting and documentation
  - Create deployment documentation for team use including recovery procedures
  - Execute deployment workflows with systematic validation
ai_coaching_level: guided
scaffolding_level: heavy
hint_strategy: progressive
common_pitfalls: []
requires_azure_subscription: true
requires_local_environment: true
tags:
  - edge-deployment
search_keywords:
  - edge-deployment-basics
  - infrastructure-as-code
  - terraform-deployment
  - deployment-troubleshooting
  - azure-infrastructure
---

## Quick Context

**You'll Learn**: Develop AI-assisted deployment workflows using structured deployment guidance for reliable infrastructure deployment and troubleshooting.

**Real Challenge**: Your edge infrastructure deployment failed mid-process, leaving resources in an inconsistent state. You need to rapidly assess the situation, plan recovery steps, and complete the deployment while documenting the issue for future prevention.

**Your Task**: Use AI-assisted deployment workflows to successfully deploy a blueprint, handle any deployment issues that arise, and validate the deployment meets requirements.

## Essential Setup

- [ ] VS Code with GitHub Copilot extension and active subscription
- [ ] Repository cloned and workspace configured; tools verified with `terraform --version && az --version`
- [ ] IaC fundamentals (Terraform/Bicep), Azure basics (resource groups, regions), Git workflows
- [ ] Understanding of Terraform resources, modules, state management, and plan/apply workflow
- [ ] Familiarity with Git operations (clone, checkout, navigate structure) and CLI proficiency
- [ ] Knowledge of Infrastructure as Code principles: declarative configuration, idempotency, state tracking
- [ ] Budget allocated: **$20-50 USD** | ⏱️ **75 minutes** (30-60 min provisioning + planning/validation/cleanup)

**Quick Validation**: Confirm Azure subscription access and resource provider availability.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** chat mode for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** mode and say:
>
> ```text
> I'm working on 01 - Deployment Basics kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Deployment Planning and Preparation (15 minutes)

**What You'll Do**: Plan a deployment using AI assistance to analyze requirements, validate prerequisites, and create execution strategy.

**Steps**:

1. **Select** a blueprint for deployment practice
   - [ ] **Copy and paste this prompt** to explore available blueprints:

   ```text
   @workspace I want to deploy a blueprint from blueprints/ to practice deployment basics. Can you explain what blueprints are available, what each one deploys, and help me choose one appropriate for learning (smaller/simpler blueprints preferred)?
   ```

   - [ ] Review the AI response and choose a blueprint (e.g., `minimum-single-node-cluster` or `only-cloud-single-node-cluster`)
   - [ ] Navigate to the blueprint directory: `cd blueprints/[blueprint-name]/terraform`
   - [ ] Read the blueprint's README.md to understand components and dependencies
   - [ ] **Expected result**: Clear understanding of what will be deployed and requirements

2. **Use** AI assistance for deployment planning
   - [ ] **Copy and paste this prompt** to analyze deployment steps:

   ```text
   @workspace For the [blueprint-name] blueprint, help me create a deployment plan. What are the deployment steps, what parameters do I need to configure, what are potential issues I should watch for, and what mitigation strategies should I have ready?
   ```

   - [ ] Review the AI response and document your deployment plan
   - [ ] Create a markdown file with: deployment steps, required parameters, potential risks, mitigation strategies
   - [ ] **Expected result**: Comprehensive deployment plan with risk assessment documented

3. **Validate** deployment prerequisites and environment readiness
   - [ ] Verify Azure subscription permissions and resource provider availability
   - [ ] Check for required tools, configurations, and dependencies
   - [ ] **Success check**: All prerequisites confirmed and deployment environment ready

### Task 2: AI-Assisted Deployment Execution (35 minutes)

**What You'll Do**: Execute the deployment using systematic AI guidance while monitoring progress and handling any issues.

**Steps**:

1. **Execute** deployment with AI monitoring and guidance
   - [ ] Ensure you're in the blueprint terraform directory: `cd blueprints/[blueprint-name]/terraform`
   - [ ] Initialize Terraform: `terraform init`
   - [ ] **Copy and paste this prompt** for parameter guidance:

   ```text
   @workspace I'm deploying [blueprint-name]. What parameters do I need to configure in terraform.tfvars? Show me an example configuration with sensible defaults for a learning/testing environment.
   ```

   - [ ] Create `terraform.tfvars` file with your parameters based on AI guidance
   - [ ] Plan the deployment: `terraform plan -out=tfplan`
   - [ ] Review the plan output carefully - check resource counts and types
   - [ ] Apply the deployment: `terraform apply tfplan`
   - [ ] Monitor progress (typically 30-60 minutes for resource provisioning)
   - [ ] **Expected result**: Deployment progressing successfully with all resources being created

2. **Handle** any deployment issues with structured troubleshooting
   - [ ] If issues arise, use AI assistance to diagnose problems quickly
   - [ ] Apply systematic troubleshooting approach with AI guidance
   - [ ] Use a scratch markdown document ro record issues and resolutions for future reference
   - [ ] **Expected result**: Any deployment problems resolved efficiently with AI support

3. **Validate** deployment success and functionality
   - [ ] Use AI assistance to verify deployment completed successfully
   - [ ] Test deployed resources meet functional requirements
   - [ ] Document deployment results and any lessons learned
   - [ ] **Success criteria**: Deployment successful with validated functionality and documented outcomes

### Task 3: Deployment Validation and Cleanup (25 minutes)

**What You'll Do**: Validate deployment success and perform mandatory resource cleanup to control costs.

**Steps**:

1. **Validate** deployment success and functionality
   - [ ] Check deployment completion: `terraform output` to view all outputs
   - [ ] Verify resources in Azure Portal - all should show "Running" or "Succeeded" status
   - [ ] Run `az resource list --output table` to list all deployed resources
   - [ ] **Copy and paste this prompt** for validation guidance:

   ```text
   @workspace My [blueprint-name] deployment completed. What are the key validation checks I should perform to confirm everything is working correctly? Provide specific commands or portal checks.
   ```

   - [ ] Perform validation checks recommended by AI
   - [ ] Document any issues or unexpected results
   - [ ] **Expected result**: All deployed resources validated as healthy and operational

2. **Cleanup** deployed resources (MANDATORY)
   - [ ] **CRITICAL**: Do not skip this step - deployments incur ongoing costs ($20-50+/day)
   - [ ] Ensure you're still in the blueprint terraform directory
   - [ ] Run `terraform destroy` to remove all infrastructure
   - [ ] Type `yes` when prompted to confirm destruction
   - [ ] Wait for completion (typically 15-25 minutes)
   - [ ] **Expected output**: "Destroy complete! Resources: XXX destroyed."
   - [ ] **Verify complete cleanup** — Run `az resource list --output table` (should return empty or only unrelated resources), check Azure Portal (all resource groups from deployment should be deleted), manually delete any remaining resources: `az group delete --name <rg-name> --yes`
   - [ ] **Success check**: Zero deployment resources remaining in Azure, no ongoing costs

3. **Document** deployment experience and lessons learned
   - [ ] Create a summary document with: what was deployed, any issues encountered, how you resolved them, key learnings
   - [ ] Use AI assistance to improve documentation quality and completeness
   - [ ] **Success criteria**: Comprehensive deployment documentation ready for future reference or team sharing

**Next Steps**: Practice with more complex edge deployment scenarios in subsequent katas.

## Completion Check

You have successfully completed this kata when you can demonstrate:

- **AI-Assisted Deployment Planning**: Plan deployments systematically using AI guidance for prerequisite validation and risk assessment
- **Deployment Execution Skills**: Execute blueprint deployments with proper configuration using terraform workflows
- **Validation Proficiency**: Verify deployment success using Azure Portal, Azure CLI, and terraform outputs
- **Resource Lifecycle Management**: Successfully deployed and cleaned up all Azure resources
- **Cost Management**: Completed full deployment cycle with proper cleanup to control costs

---

## Reference Appendix

### Help Resources

- **Learning Kata Coach**: Use for step-by-step guidance and progressive troubleshooting hints
- **Deploy Prompt**: Structured deployment guidance for systematic workflows
- **Project Blueprints**: Reference blueprint README files in `/blueprints/` for deployment-specific guidance

### Professional Tips

- Always verify prerequisites before starting deployment to avoid mid-process failures
- Document each deployment step for troubleshooting and recovery purposes
- Use AI assistance proactively during deployment rather than only when issues arise

### Troubleshooting

**Issue**: Terraform authentication failures during init or plan
**Solution**: Run `source ./scripts/az-sub-init.sh` to configure Azure authentication

**Issue**: Deployment fails with infrastructure conflicts
**Solution**: Use deploy prompt to analyze conflicts and plan resolution steps systematically

**Issue**: Multi-component integration issues during deployment
**Solution**: Follow systematic troubleshooting with component-by-component validation

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
