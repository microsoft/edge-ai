---
title: 'Kata: 300 - Multi-Blueprint Coordination'
description: Learn multi-blueprint coordination for complex edge deployment scenarios with dependency management and staged deployment strategies
author: Edge AI Team
ms.date: 2025-01-20
kata_id: edge-deployment-300-multi-blueprint-coordination
kata_category:
  - edge-deployment
kata_difficulty: 3
estimated_time_minutes: 90
learning_objectives:
  - Learn coordination between multiple blueprint deployments
  - Understand dependency management across edge and cloud components
  - Practice layered deployment strategies for complex scenarios
  - Develop expertise with multi-environment orchestration
prerequisite_katas:
  - edge-deployment-100-deployment-basics
  - edge-deployment-100-resource-management
technologies:
  - Terraform
  - Azure
  - GitHub Copilot
success_criteria:
  - Coordinate complex multi-blueprint deployment scenarios
  - Manage dependencies between infrastructure components
  - Implement staged deployment strategies for enterprise environments
  - Validate multi-component integration and operational readiness
ai_coaching_level: guided
scaffolding_level: medium
hint_strategy: progressive
common_pitfalls: []
requires_azure_subscription: true
requires_local_environment: true
tags:
  - edge-deployment
search_keywords:
  - multi-blueprint-deployment
  - deployment-orchestration
  - dependency-management
  - staged-deployment
  - enterprise-coordination
---

## Quick Context

**You'll Learn**: Develop AI-assisted workflows for coordinating multiple interconnected blueprints with sophisticated resource sharing and dependency management.

**Prerequisites**: Completion of Deployment Basics kata, understanding of blueprint dependencies, familiarity with Terraform/Bicep resource referencing

**Real Challenge**: You need to deploy a multi-tier edge AI solution that requires coordinated deployment of cloud infrastructure and edge components across multiple blueprints. The blueprints have complex dependencies and shared resources that must be managed carefully.

**Your Task**: Plan and execute a multi-blueprint deployment using AI assistance to handle resource sharing, dependency coordination, and deployment sequencing for a complete edge AI solution.

## Essential Setup

- [ ] Completed edge-deployment-100-deployment-basics and edge-deployment-100-resource-management katas
- [ ] Azure CLI with subscription access; multiple blueprints available (recommend: `only-cloud-single-node-cluster` + `only-edge-iot-ops`)
- [ ] **Terraform/Bicep Knowledge**: Understand resource referencing with data sources, outputs, and variable passing between modules
- [ ] **Blueprint Architecture**: Familiar with component dependencies and deployment ordering from previous katas
- [ ] **Azure Resource Dependencies**: Understanding of VNet dependencies, identity propagation, storage coordination, and compute relationships
- [ ] **Git Workflow**: Know how to track infrastructure state changes across multiple deployments
- [ ] **Budget allocated**: **$30-60 USD** (2-3 blueprints) for this kata session
- [ ] **Time allocated**: ⏱️ **150 minutes total** (60-120 min provisioning + 30 min planning/validation/cleanup)
- [ ] **⚠️ Cost Warning**: Multi-blueprint deployments multiply costs. Plan to complete this kata and cleanup within one extended session to minimize costs

**Quick Validation**: Verify blueprint directory access with Terraform/Azure CLI installed.
>
> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** chat mode for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** mode and say:
>
> ```text
> I'm working on 03 - Multi-Blueprint Coordination kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Blueprint Dependency Analysis and Planning (25 minutes)

**What You'll Do**: Analyze complex blueprint relationships using the Dependency Analysis Framework to create a comprehensive deployment plan.

**Steps**:

1. **Select blueprints for multi-blueprint deployment**
   - [ ] Choose 2-3 blueprints for coordinated deployment (recommended: `only-cloud-single-node-cluster` + `only-edge-iot-ops`)
   - [ ] Review each blueprint's README.md to understand what it deploys
   - [ ] **Expected result**: Clear list of blueprints and high-level understanding of each

2. **Analyze blueprint dependencies using the framework**
   - [ ] For each blueprint, identify required inputs (look for variables without defaults)
   - [ ] For each blueprint, identify generated outputs (terraform output or bicep output)
   - [ ] Copy and paste this prompt to your AI assistant:

     ```text
     @workspace I'm planning a multi-blueprint deployment with [list your blueprints]. Can you help me:
     1. Identify what outputs each blueprint generates (review terraform/bicep output files)
     2. Identify what inputs each blueprint requires (review variables/parameters)
     3. Map which outputs from blueprint A become inputs to blueprint B
     4. Determine the correct deployment order based on dependencies
     Create a dependency map showing the relationships.
     ```

   - [ ] Create a Dependency Mapping Table (use the framework template from above)
   - [ ] **Expected result**: Completed dependency table with deployment order

3. **Decide on blueprint layering strategy**
   - [ ] Review the Blueprint Layering Decision Matrix
   - [ ] Determine if layered deployment is appropriate for your scenario
   - [ ] Copy and paste this prompt to your AI assistant:

     ```text
     @workspace For my deployment scenario [describe: dev/prod, single-tenant/multi-tenant, etc.], should I:
     1. Deploy blueprints sequentially (layered approach)
     2. Combine blueprints into single deployment
     3. Use a hybrid approach
     What are the trade-offs for my specific scenario? Provide recommendation with rationale.
     ```

   - [ ] Document layering decision and rationale
   - [ ] **Expected result**: Clear layering strategy decision with trade-off analysis

4. **Map resource sharing patterns**
   - [ ] Review the Resource Sharing Patterns Checklist
   - [ ] Identify which patterns apply to your selected blueprints
   - [ ] For each shared resource, document — **Source** (which blueprint creates it), **Targets** (which blueprint(s) consume it), **Reference mechanism** (how it's referenced: data source, existing resource, output reference)
   - [ ] Copy and paste this prompt to your AI assistant:

     ```text
     @workspace For my multi-blueprint deployment [list blueprints], help me:
     1. Identify all shared resources between blueprints (VNet, identity, ACR, Key Vault, etc.)
     2. For each shared resource, show me how to export it from the source blueprint
     3. For each shared resource, show me how to import/reference it in the target blueprint
     4. Provide example Terraform code (or Bicep) for the export and import patterns
     ```n
   - [ ] **Success check**: Comprehensive resource sharing map with export/import mechanisms

5. **Define validation checkpoints**
   - [ ] For each blueprint in deployment sequence, define validation checks to run before deploying the next — **Foundation blueprint validation** (verify resource group, VNet, Key Vault, ACR exist and are accessible), **Edge blueprint validation** (verify cluster connected to Arc, IoT Operations namespace created)
   - [ ] Document specific commands for each validation checkpoint
   - [ ] **Expected result**: Detailed deployment sequence plan with validation strategy

### Task 2: Coordinated Multi-Blueprint Deployment (40 minutes)

**What You'll Do**: Execute systematic deployment of multiple blueprints with proper dependency coordination, validation checkpoints, and integration testing.

**Steps**:

1. **Deploy foundation blueprint (first in sequence)**
   - [ ] Navigate to foundation blueprint directory (e.g., `cd blueprints/only-cloud-single-node-cluster/terraform`)
   - [ ] Initialize Terraform: `terraform init`
   - [ ] Create terraform.tfvars with required parameters
   - [ ] Review plan: `terraform plan -out=tfplan`
   - [ ] Apply: `terraform apply tfplan`
   - [ ] Wait for completion (30-60 minutes for cloud resources)
   - [ ] **Expected result**: Foundation blueprint deployed successfully

2. **Validate foundation blueprint outputs**
   - [ ] List all outputs: `terraform output`
   - [ ] Verify critical outputs exist using these terraform output commands: `terraform output resource_group_name`, `terraform output vnet_id`, `terraform output keyvault_id`, `terraform output acr_login_server`, and other required outputs
   - [ ] Document output values (you'll need these for the next blueprint)
   - [ ] Verify resources in Azure Portal — **Resource group** (created), **VNet and subnets** (exist), **Key Vault** (accessible), **ACR** (created and accessible)
   - [ ] Run Azure CLI validation:

     ```bash
     az group show --name $(terraform output -raw resource_group_name)
     az network vnet show --ids $(terraform output -raw vnet_id)
     az keyvault show --ids $(terraform output -raw keyvault_id)
     ```

   - [ ] **Expected result**: All foundation resources validated and outputs documented

3. **Configure dependent blueprint with resource sharing**
   - [ ] Navigate to dependent blueprint directory (e.g., `cd blueprints/only-edge-iot-ops/terraform`)
   - [ ] Copy and paste this prompt to your AI assistant:

     ```text
     @workspace I just deployed [foundation-blueprint] and have these outputs: [paste terraform output]. Now I need to deploy [dependent-blueprint]. Can you help me:
     1. Identify which variables in the dependent blueprint should use outputs from the foundation
     2. Show me how to configure terraform.tfvars to reference the foundation outputs
     3. Explain if I need to use data sources or if I can just copy output values
     Provide a complete terraform.tfvars example for the dependent blueprint.
     ```

   - [ ] Create terraform.tfvars for dependent blueprint using foundation outputs
   - [ ] For shared resources, decide: copy output values OR use Terraform data sources
     - **Copy values**: Simpler, but loses dynamic linkage
     - **Data sources**: Dynamic, but requires foundation state access
   - [ ] **Expected result**: Dependent blueprint configured with proper resource references

4. **Deploy dependent blueprint with monitoring**
   - [ ] Initialize Terraform: `terraform init`
   - [ ] Review plan carefully: `terraform plan -out=tfplan`
   - [ ] Verify plan shows correct resource references (no "will be created" for shared resources)
   - [ ] Apply: `terraform apply tfplan`
   - [ ] Monitor deployment progress (30-60 minutes for IoT Operations)
   - [ ] **Expected result**: Dependent blueprint deployed successfully with resource integration

5. **Validate end-to-end integration**
   - [ ] Copy and paste this prompt to your AI assistant:

     ```text
     @workspace I've deployed [list all blueprints] in sequence. Help me validate end-to-end integration:
     1. What are the key integration points I should test (network connectivity, identity access, registry access)?
     2. Provide specific validation commands for each integration point
     3. How do I verify shared resources are properly configured and accessible from all blueprints?
     ```

   - [ ] Test connectivity between blueprint components — **Edge cluster can pull images from shared ACR**, **Edge workloads can access shared Key Vault secrets**, **Edge logs flow to shared Log Analytics workspace**
   - [ ] Verify IoT Operations functionality:

     ```bash
     kubectl get pods -n azure-iot-operations
     kubectl get broker -n azure-iot-operations
     ```

   - [ ] Test basic MQTT message flow
   - [ ] **Success check**: Complete multi-blueprint system with validated integration

6. **Cleanup deployed resources (MANDATORY)**
   - [ ] **CRITICAL**: Multi-blueprint deployments cost $30-60+ per day. Do not skip cleanup.
   - [ ] **Cleanup Order**: Reverse of deployment order (dependent blueprints first, foundation last)
   - [ ] Navigate to dependent blueprint: `cd blueprints/[dependent-blueprint]/terraform`
   - [ ] Destroy dependent resources: `terraform destroy` (type `yes`)
   - [ ] Wait for completion (15-25 minutes)
   - [ ] Verify dependent cleanup: `az resource list --resource-group [rg-name] --output table`
   - [ ] Navigate to foundation blueprint: `cd blueprints/[foundation-blueprint]/terraform`
   - [ ] Destroy foundation resources: `terraform destroy` (type `yes`)
   - [ ] Wait for completion (15-25 minutes)
   - [ ] Verify complete cleanup:

     ```bash
     az group list --query "[].name" --output table
     # Verify your resource groups are deleted
     ```

   - [ ] **Manual cleanup if needed**: If resources remain:

     ```bash
     az group delete --name [resource-group-name] --yes --no-wait
     ```n
   - [ ] **Expected result**: All deployed Azure resources deleted, no ongoing costs

## Completion Check

**Confirm you can:**

1. **Plan**: Map dependencies between multiple blueprints with clear deployment order

2. **Strategize**: Make informed decisions about blueprint layering vs. single deployment

3. **Execute**: Successfully deploy multiple coordinated blueprints with proper resource sharing

4. **Validate**: Verify integration and functionality across the complete blueprint stack

5. **Cleanup**: Properly tear down multi-blueprint deployments in reverse dependency order

**Reflection Questions**:

1. What are the trade-offs between layered blueprints and a single comprehensive blueprint?

2. How do you handle dependency conflicts between multiple blueprint deployments?

3. What validation checkpoints should you include between sequential blueprint deployments?

4. Why is cleanup order critical in multi-blueprint deployments? What happens if you delete foundation resources before dependent resources?

5. How do you verify that all resources from a multi-blueprint deployment have been properly cleaned up?

**You've Succeeded When**:

- [ ] Successfully analyzed and mapped complex blueprint dependencies

- [ ] Executed coordinated deployment of multiple interconnected blueprints

- [ ] Validated proper resource sharing and configuration inheritance

- [ ] Demonstrated understanding of deployment sequencing and dependency management

---

## Reference Appendix

### Help Resources

- [Azure Resource Manager][azure-resource-manager] - Resource sharing and dependency management patterns

- [Project Blueprints][project-blueprints] - Blueprint architecture and integration patterns

- [Terraform State Management][terraform-state] - Managing state across multiple configurations

- [Blueprint Documentation](/blueprints/README.md) - Detailed blueprint patterns and examples

- [Component Dependencies](/src/README.md) - Understanding component relationships

### Professional Tips

**Blueprint Dependency Analysis**:

- Create a dependency mapping table for your deployment listing each blueprint, what it depends on, what outputs it provides, and the deployment order
- Systematically identify required inputs (variables without defaults) and generated outputs for each blueprint
- Map which outputs from parent blueprints become inputs to child blueprints to determine correct sequencing

**Blueprint Layering Strategy**:

- Use layered blueprints for cloud + edge deployments, production with DR, multi-tenant scenarios, and when team ownership boundaries exist
- Consider single blueprints for rapid development/testing iteration when flexibility is less critical
- Key trade-offs: Layered blueprints offer modularity and reusability but add complexity; single blueprints are simpler but less flexible

**Resource Sharing Patterns**:

- Common shared resources: Virtual networks, managed identities, Log Analytics workspaces, container registries, Key Vaults, storage accounts, messaging infrastructure
- Export patterns: Use Terraform outputs or Bicep outputs to expose resource IDs, names, and connection details
- Import patterns: Reference via Terraform data sources or Bicep existing resources when dynamic linkage needed; copy output values for simpler static references
- Share cross-cutting concerns (networking, identity, observability) and expensive resources; isolate workload-specific resources and security boundaries

- Start with simpler two-blueprint combinations before attempting complex multi-blueprint deployments

- Document dependency chains clearly before beginning deployment to avoid confusion

- Use version control tags to track known-good blueprint combinations

- Test incremental deployments in development before production rollout

- Keep deployment plans versioned alongside infrastructure code

- Consider using Terraform workspaces or separate state files for blueprint isolation

### Troubleshooting

**Deployment fails with "Resource not found" errors**:

- Dependent resource from previous blueprint not yet available

- Check: Verify prerequisite blueprint deployed successfully and outputs are accessible

- Solution: Review deployment order, ensure dependencies complete before dependent blueprints start

**Configuration values not propagating between blueprints**:

- Blueprint outputs not properly referenced or state file issues

- Check: Verify output definitions in source blueprint and input references in dependent blueprint

- Solution: Use `terraform output` to validate outputs, ensure state files are accessible

**Multiple blueprints conflict over resource ownership**:

- Two blueprints attempting to manage the same resource

- Check: Review Terraform plans for resource conflicts before applying

- Solution: Refactor to ensure single-ownership model, use data sources for shared resource references

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
[project-blueprints]: /blueprints/README
[azure-resource-manager]: https://learn.microsoft.com/en-us/azure/azure-resource-manager/
[terraform-state]: https://developer.hashicorp.com/terraform/language/state
