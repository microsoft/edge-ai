---
title: 'Kata: 200 - Prerequisite Full Deployment'
description: Deploy complete Edge AI infrastructure stack as foundation for Microsoft Fabric RTI integration
author: Edge AI Team
ms.date: 2025-01-20
kata_id: fabric-integration-200-prerequisite-full-deployment
kata_category:
  - fabric-integration
kata_difficulty: 2
estimated_time_minutes: 60
learning_objectives:
  - Deploy multi-component edge AI infrastructure using blueprints
  - Validate Arc-enabled Kubernetes cluster connectivity
  - Verify Azure IoT Operations workload deployment
  - Confirm infrastructure prerequisites for Fabric RTI integration
prerequisite_katas: []
technologies:
  - Terraform
  - Azure Arc
  - Azure IoT Operations
  - Kubernetes
  - Azure
success_criteria:
  - Successfully deploy full-single-node-cluster blueprint
  - Validate all 8 prerequisite components for Fabric integration
  - Confirm Arc-connected cluster health and AIO workload status
  - Demonstrate infrastructure readiness for RTI connectivity
ai_coaching_level: guided
scaffolding_level: medium-heavy
hint_strategy: progressive
common_pitfalls:
  - Incomplete Arc connection setup - Ensure Arc agents are running before validating cluster connectivity
  - AIO workload deployment delays - IoT Operations can take 15-20 minutes to reach ready state after deployment
  - Networking misconfiguration issues - Verify VM/cluster has internet connectivity for Arc registration
requires_azure_subscription: true
requires_local_environment: true
tags:
  - edge-deployment
  - fabric-integration
search_keywords:
  - edge-ai-deployment
  - arc-kubernetes
  - iot-operations
  - infrastructure-prerequisites
---

## Quick Context

**You'll Learn**: Deploy the complete Edge AI infrastructure stack required as the foundation for Microsoft Fabric Real-Time Intelligence integration. This kata establishes all prerequisite components needed for subsequent Fabric workspace configuration and data pipeline implementation.

**Prerequisites**: Active Azure subscription with Contributor or Owner role, Terraform and Azure CLI installed, understanding of basic cloud infrastructure concepts

**Real Challenge**: Microsoft Fabric RTI integration requires a fully deployed Edge AI stack including Arc-enabled Kubernetes, Azure IoT Operations, managed identities, and custom locations. You need to deploy and validate this complete infrastructure before any Fabric integration can begin.

**Your Task**: Deploy the `full-single-node-cluster` blueprint to create all required infrastructure components, then systematically verify each prerequisite for Fabric RTI integration readiness.

## Essential Setup

**Complete these checks before starting** - verifying your setup ensures successful kata completion:

**Required** (check these first):

- [ ] Active Azure subscription with Contributor or Owner role

- [ ] Azure CLI installed and logged in (`az login` completed)

- [ ] Terraform CLI installed (version 1.5.0 or later)

- [ ] Git repository cloned locally

- [ ] Sufficient Azure quota for VM deployment (4-8 vCPUs minimum)

**Quick Validation**: Verify you can run `az account show`, `terraform version`, and access the `blueprints/full-single-node-cluster/terraform/` directory.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on 01 - Prerequisite Full Deployment kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Blueprint Analysis and Configuration (20 minutes)

**What You'll Do**: Understand the full-single-node-cluster blueprint architecture and prepare deployment configuration

**Steps**:

1. **Analyze the blueprint structure** using AI assistance

   ```copilot-prompt
   Analyze the full-single-node-cluster blueprint architecture:

   1. Read blueprints/full-single-node-cluster/terraform/main.tf
   2. List all component modules being deployed (resource group, networking, VM, Arc, AIO, etc.)
   3. Explain the dependency relationships between components
   4. Identify which outputs are critical for Fabric RTI integration

   Provide a component deployment diagram showing the order of creation.
   ```

   - [ ] **Expected result**: Clear understanding of 8+ components and their deployment sequence

2. **Review variable requirements** and create configuration

   ```copilot-prompt
   Help me create a terraform.tfvars file for full-single-node-cluster deployment:

   1. Read blueprints/full-single-node-cluster/terraform/variables.tf
   2. Identify all required variables (no default values)
   3. Suggest sensible values for:
      - environment = "dev"
      - resource_prefix = "edgeai"
      - location = "eastus"
      - instance = "001"
   4. Generate complete terraform.tfvars file content

   Include comments explaining each variable's purpose.
   ```

   - [ ] **Expected result**: Complete `terraform.tfvars` file ready for deployment

3. **Validate prerequisites and plan deployment**

   ```bash
   # Navigate to blueprint directory
   cd blueprints/full-single-node-cluster/terraform/

   # Initialize Terraform (downloads providers and modules)
   terraform init

   # Validate configuration syntax
   terraform validate

   # Generate deployment plan
   terraform plan -out=tfplan
   ```

   - [ ] **Success check**: `terraform plan` completes successfully showing 40-60 resources to create

### Task 2: Infrastructure Deployment and Monitoring (40 minutes)

**What You'll Do**: Deploy the complete edge AI infrastructure stack and monitor progress through multiple deployment phases

**Steps**:

1. **Execute deployment** with progress monitoring

   ```bash
   # Apply the deployment plan
   terraform apply tfplan

   # Deployment will proceed through phases:
   # Phase 1 (5-10 min): Resource group, networking, security
   # Phase 2 (10-15 min): VM provisioning and K3s installation
   # Phase 3 (10-15 min): Arc connection and custom location
   # Phase 4 (15-20 min): Azure IoT Operations deployment
   ```

   - [ ] **Expected result**: Terraform apply completes successfully with all resources created

2. **Monitor Arc connection status** during deployment

   ```copilot-prompt
   Create an Azure CLI command sequence to monitor Arc-connected cluster deployment:

   1. List Arc-connected clusters in resource group
   2. Show connection status for specific cluster
   3. Verify Arc agents are running
   4. Check custom location creation

   Include commands with example output formatting.
   ```

   Then execute the commands:

   ```bash
   # List Arc clusters (replace with your resource group name)
   az connectedk8s list --resource-group <your-rg-name> --output table

   # Check Arc cluster connection status
   az connectedk8s show --name <cluster-name> --resource-group <your-rg-name> --query "connectivityStatus"
   ```

   - [ ] **Expected result**: Arc cluster shows "Connected" status

3. **Validate Azure IoT Operations deployment**

   ```copilot-prompt
   Help me verify Azure IoT Operations deployment status:

   1. Provide Azure CLI commands to list AIO instances
   2. Show how to check AIO instance provisioning state
   3. Create kubectl commands to verify AIO pods are running (if cluster access available)

   Include troubleshooting steps if AIO shows "Provisioning" status for >20 minutes.
   ```

   Then verify deployment:

   ```bash
   # List AIO instances
   az iot ops list --resource-group <your-rg-name> --output table

   # Check specific AIO instance status
   az iot ops show --name <aio-instance-name> --resource-group <your-rg-name> --query "provisioningState"
   ```

   - [ ] **Success check**: AIO instance shows "Succeeded" provisioning state

### Task 3: Infrastructure Validation and Prerequisites Verification (30 minutes)

**What You'll Do**: Systematically verify all 8 prerequisite components required for Fabric RTI integration

**Infrastructure Prerequisites Checklist**:

Use this checklist to verify each component exists and is healthy:

| # | Component                         | Verification Method                                                        | Status |
|---|-----------------------------------|----------------------------------------------------------------------------|--------|
| 1 | **Resource Group**                | `az group show --name <rg-name>`                                           | ☐      |
| 2 | **Managed Identity**              | `az identity show --name <identity-name> --resource-group <rg-name>`       | ☐      |
| 3 | **Virtual Network** (if deployed) | `az network vnet show --name <vnet-name> --resource-group <rg-name>`       | ☐      |
| 4 | **VM Host**                       | `az vm show --name <vm-name> --resource-group <rg-name>`                   | ☐      |
| 5 | **Arc-connected Cluster**         | `az connectedk8s show --name <cluster-name> --resource-group <rg-name>`    | ☐      |
| 6 | **Custom Location**               | `az customlocation show --name <location-name> --resource-group <rg-name>` | ☐      |
| 7 | **AIO Instance**                  | `az iot ops show --name <aio-name> --resource-group <rg-name>`             | ☐      |
| 8 | **Terraform State**               | Verify `terraform.tfstate` contains all deployed resources                 | ☐      |

**Steps**:

1. **Generate verification script** using AI assistance

   ```copilot-prompt
   Create a bash script to verify all Fabric RTI prerequisites:

   1. Read terraform.tfstate to extract resource names
   2. Check each of the 8 components listed in the table above
   3. Output status for each component (✓ or ✗)
   4. Provide summary of readiness for Fabric integration

   Script should accept resource group name as parameter.
   ```

   - [ ] **Expected result**: Verification script shows all 8 components are healthy

2. **Document infrastructure outputs** needed for Fabric integration

   ```bash
   # Display Terraform outputs
   terraform output

   # Save critical outputs to file for next kata
   terraform output -json > ../fabric-integration-prereqs.json
   ```

   Critical outputs to capture:
   - Resource group name
   - Managed identity client ID and resource ID
   - AIO instance name and ID
   - Custom location name and ID
   - Arc cluster name and ID

   - [ ] **Expected result**: JSON file with all prerequisite resource identifiers

3. **Test infrastructure connectivity and health**

   ```copilot-prompt
   Create end-to-end connectivity tests for deployed infrastructure:

   1. Test VM accessibility (if SSH enabled)
   2. Verify Arc cluster heartbeat is active
   3. Check AIO core services are running
   4. Validate managed identity has required RBAC roles

   Provide Azure CLI and kubectl commands (if applicable).
   ```

   - [ ] **Success check**: All connectivity tests pass, infrastructure is ready for Fabric workspace configuration

## Completion Check

**You've Succeeded When**:

- [ ] `full-single-node-cluster` blueprint deployed successfully via Terraform

- [ ] All 8 prerequisite components verified and healthy

- [ ] Arc-connected Kubernetes cluster shows "Connected" status

- [ ] Azure IoT Operations instance shows "Succeeded" provisioning state

- [ ] Terraform outputs captured for use in subsequent Fabric integration katas

- [ ] Infrastructure passes end-to-end connectivity and health validation

**What You've Built**:

You now have a complete Edge AI infrastructure stack including:

- Azure resource group with all cloud resources

- VM-based Kubernetes cluster (K3s) connected via Azure Arc

- Azure IoT Operations deployed and operational

- Managed identities and RBAC configured

- Custom location for extension deployment

- All prerequisites ready for Microsoft Fabric RTI integration

**Next Steps**: Continue to **02 - Fabric Workspace Configuration** kata to provision Fabric capacity, create workspace, and configure Eventhouse for RTI capabilities.

---

## Reference Appendix

### Help Resources

- **Blueprint Documentation**: Reference `blueprints/full-single-node-cluster/README.md` for architecture details

- **Component Details**: Explore component source in `src/000-cloud/` and `src/100-edge/` directories

- **Terraform Instructions**: Follow `.github/instructions/terraform.instructions.md` for best practices

- **Deployment Troubleshooting**: Check `docs/build-cicd/` for common deployment issues

### Professional Tips

- **Deployment Time**: Budget 60-90 minutes for full deployment including validation

- **Resource Monitoring**: Keep Azure Portal open to watch resource creation in real-time

- **State Management**: Keep `terraform.tfstate` secure - it contains all resource mappings

- **Incremental Validation**: Don't wait for full deployment - validate Arc connection as soon as Phase 3 completes

- **Cleanup Planning**: Document deployed resources for later cleanup to avoid unnecessary costs

### Troubleshooting

**Issue**: Arc connection stuck in "Connecting" status

```copilot-prompt
Troubleshoot Arc connection issues:

1. Check VM network connectivity (can it reach Azure Arc endpoints?)

2. Verify Arc agents are running on cluster

3. Review Arc connection logs

4. Validate service principal permissions

Provide diagnostic commands and resolution steps.

```

**Issue**: AIO deployment fails or stays in "Provisioning" state

```copilot-prompt
Debug Azure IoT Operations deployment failure:

1. Check AIO instance deployment logs in Azure Portal

2. Verify custom location is available and healthy

3. Review Arc extension deployment status

4. Check cluster resource availability (CPU, memory)

Provide Azure CLI commands to diagnose and resolve.

```

**Issue**: Terraform apply fails with quota/capacity errors

- **Quick Fix**: Request quota increase via Azure Portal (Support → New Support Request → Service and subscription limits), or deploy in different region with available capacity

- **Alternative**: Use smaller VM SKU (Standard_D4s_v3 instead of D8s_v3) for learning purposes

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->

**Ready to practice?** 🚀 **Start with Essential Setup above**
