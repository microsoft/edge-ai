---
title: 'Kata: 400 - Multi-Cluster Workload Orchestration'
description: Learn multi-cluster workload orchestration using Kalypso to manage applications across distributed edge environments with GitOps-based scheduling and platform configuration
author: Edge AI Team
ms.date: 2025-11-25
kata_id: edge-deployment-400-workload-orchestration
kata_category:
  - edge-deployment
kata_difficulty: 4
estimated_time_minutes: 120
learning_objectives:
  - Implement multi-cluster workload orchestration using Kalypso control plane
  - Configure GitOps-based application deployment across distributed environments
  - Design and apply scheduling policies for cluster type assignment
  - Manage platform-specific configurations across development and QA environments
prerequisite_katas:
  - edge-deployment-100-deployment-basics
technologies:
  - Kalypso
  - GitOps
  - Flux
  - Azure Arc
  - Kubernetes
  - Helm
success_criteria:
  - Successfully deploy Kalypso control plane and configure multi-environment orchestration
  - Implement workload registration and deployment target assignment
  - Create scheduling policies for cluster type-based application distribution
  - Configure platform-specific settings across environments and regions
ai_coaching_level: adaptive
scaffolding_level: light
hint_strategy: progressive
common_pitfalls:
  - Forgetting to update GitHub organization placeholders in YAML files
  - Not waiting for Kalypso control plane to create PRs after configuration changes
  - Missing GitOps configuration on Arc clusters for environment subscription
  - Incorrect label selectors in scheduling policies
requires_azure_subscription: true
requires_local_environment: true
tags:
  - edge-deployment
search_keywords:
  - workload-orchestration
  - kalypso-orchestration
  - multi-cluster-management
  - gitops-deployment
  - cluster-scheduling
  - platform-configuration
---

## Quick Context

**You'll Learn**: Implement enterprise-grade multi-cluster workload orchestration using Kalypso to manage application deployments across distributed edge environments with automated scheduling and configuration management.

**Real Challenge**: As a platform engineer at a manufacturing company, you manage edge infrastructure across multiple regions. Your application teams deploy workloads manually to each site, causing configuration drift, deployment delays, and operational overhead. You need to implement automated orchestration that schedules workloads to appropriate clusters based on policies while maintaining environment-specific configurations.

**Your Task**: Set up Kalypso-based workload orchestration to automate multi-cluster deployments, implement scheduling policies for cluster assignment, and manage platform configurations across development and QA environments.

## Essential Setup

- [ ] VS Code with GitHub Copilot and repository cloned
- [ ] Existing Azure Arc-enabled Kubernetes cluster for deployment
- [ ] Required tools and accounts are ready as described in [Kalypso Workload Orchestration](../../../src/600-workload-orchestration/600-kalypso/README.md#prerequisites)
- [ ] Budget allocated: **$50-100 USD** | ⏱️ **120 minutes** (setup, configuration, validation, cleanup)

**Quick Validation**: Run `az connectedk8s list --output table` to verify Arc cluster connectivity and `gh auth status` to confirm GitHub CLI authentication.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on 400 - Multi-Cluster Workload Orchestration kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Deploy Kalypso Control Plane (30 minutes)

<!-- AI_COACH: This phase establishes the orchestration foundation. If learners struggle with parameter selection, guide them to review their existing Azure resources and GitHub organization. Encourage reviewing the setup script parameters before execution to understand what infrastructure will be created. -->

**What You'll Do**: Deploy the Kalypso control plane infrastructure and configure initial orchestration repositories.

**Steps**:

1. **Navigate** to the workload orchestration directory
   - [ ] Change to orchestration directory: `cd src/600-workload-orchestration/600-kalypso/basic-inference-workload-orchestration/`
   - [ ] Review the tutorial README to understand Kalypso architecture and repository structure
   - **Pro tip**: The setup script creates 5 GitHub repositories (application source, application config, application gitops, control plane, platform gitops) and the Kalypso AKS cluster
   - [ ] **Expected result**: Understanding of how these 5 repositories interact in the orchestration flow

2. **Execute** the Kalypso setup script with your environment parameters
   - [ ] Run setup command with your specific values:

   ```bash
   ./basic-inference-workload.sh \
     --org your-github-org \
     --arc-cluster your-arc-cluster \
     --arc-rg your-resource-group \
     --kalypso-cluster kalypso-control-plane \
     --kalypso-rg rg-kalypso-control \
     --kalypso-location eastus
   ```

   - [ ] Monitor script execution for successful completion messages
   - **Validation checkpoint**: Did the script create all required repositories and infrastructure?
   - [ ] **Expected result**: Script completes successfully, creating Kalypso AKS cluster and GitHub repositories

3. **Verify** control plane deployment and repository creation
   - [ ] Check Azure portal for Kalypso AKS cluster in the specified resource group
   - [ ] Visit GitHub organization to confirm new repositories exist
   - [ ] Verify Arc cluster has `platform-dev` GitOps configuration in Azure portal
   - **Success check**: All repositories created, AKS cluster running, Arc cluster configured

### Task 2: Onboard Application to Control Plane (25 minutes)

<!-- AI_COACH: Workload registration is where application teams request compute resources from the platform. Rather than providing exact file paths, encourage learners to explore the repository structure created by the setup script. Ask them to consider how the control plane discovers workload requirements and what information it needs. -->

**What You'll Do**: Register the basic-inference application with the Kalypso control plane and understand deployment target assignment.

**Steps**:

1. **Locate** and examine the workload definition in the application source repository
   - [ ] Navigate to your GitHub organization and open the `basic-inference-orchestration` repository
   - [ ] Find `workload/workload.yaml` and review the deployment target definitions
   - **Validation checkpoint**: What environments does the application request deployment to? What labels are defined on the workload?
   - [ ] **Expected result**: Understanding of how applications declare deployment requirements

2. **Create** workload registration in the control plane repository
   - [ ] Clone the `kalypso-control-plane` repository to your local machine
   - [ ] Review the `sample-workload-registration.yaml` file in the repository as a reference
   - [ ] Create directory `workloads/` in the main branch
   - [ ] Create `workloads/basic-inference-workload-registration.yaml` based on the sample, pointing to your `basic-inference-orchestration` repository
   - [ ] Update the repository URL placeholder to match your GitHub organization
   - [ ] Commit and push the registration file to the main branch
   - **Pro tip**: The WorkloadRegistration tells the control plane where to find the workload definition - it's a pointer to the application repository
   - [ ] **Expected result**: Workload registration file committed to control plane repository

3. **Monitor** control plane scheduling and PR creation
   - [ ] Wait for Kalypso scheduler to process the registration (typically a few seconds)
   - **Pro tip**: Only changes to the main branch trigger CI/CD workflows - the Kalypso Scheduler processes other branch changes immediately
   - [ ] Check `kalypso-platform-gitops` repository for PR to the `dev` branch
   - [ ] Review PR contents: namespace.yaml, platform-config.yaml (with initial values), reconciler.yaml
   - **Validation checkpoint**: Can you explain what each generated manifest does? What initial values are in platform-config?
   - [ ] Merge the PR to complete dev environment assignment
   - [ ] **Expected result**: Application assigned to dev cluster type with GitOps reconciliation configured

### Task 3: Configure QA Environment Scheduling (30 minutes)

<!-- AI_COACH: Scheduling policies control where applications run. If learners struggle with label selectors, guide them to examine the cluster type definitions and workload labels. Encourage thinking about how the platform team controls application placement without knowing specific application details. -->

**What You'll Do**: Configure QA environment with multiple cluster types and implement scheduling policies for regional distribution.

**Steps**:

1. **Review** QA environment cluster types in the control plane repository
   - [ ] Checkout the `qa` branch in the `kalypso-control-plane` repository
   - [ ] Navigate to `cluster-types/` folder and review `east-us.yaml` and `west-us.yaml`
   - **Pro tip**: The key difference is the reconciler - east-us uses ArgoCD (`reconciler: argocd`) while west-us uses Flux (`reconciler: arc-flux`)
   - **Validation checkpoint**: What differences exist between east-us and west-us cluster types?
   - [ ] **Expected result**: Understanding of cluster type configurations and regional differences

2. **Create** scheduling policy for west-us cluster assignment
   - [ ] Create `scheduling-policies/basic-inference-policy.yaml` in the `qa` branch
   - [ ] Define SchedulingPolicy with appropriate label selectors
   - [ ] Match workload label `workload: basic-inference` to cluster label `region: westus`
   - **Pro tip**: The policy targets west-us (Flux-based) to match your Arc cluster's Flux configuration. East-us clusters use ArgoCD instead
   - [ ] Commit and push the policy to the `qa` branch
   - [ ] **Expected result**: Scheduling policy committed to control plane repository

3. **Verify** assignment PR creation and merge
   - [ ] Wait for Kalypso scheduler to process the scheduling policy (typically a few seconds)
   - [ ] Check `kalypso-platform-gitops` repository for PR to `qa` branch
   - [ ] Review assignment manifests in the `west-us/` folder
   - **Validation checkpoint**: Why are manifests in west-us folder and not east-us? (Hint: scheduling policy matched region: westus, and your Arc cluster uses Flux like west-us cluster type)
   - [ ] Merge the PR to complete QA cluster type assignment
   - [ ] **Expected result**: Application assigned to west-us cluster type in QA environment

### Task 4: Add Cluster to Environment and Deploy Application (20 minutes)

<!-- AI_COACH: This phase connects physical clusters to logical cluster types. Encourage learners to think about the separation of concerns: application teams define what to deploy, platform teams define where it runs, and cluster operators subscribe to relevant assignments. -->

**What You'll Do**: Subscribe your Arc cluster to the QA environment and deploy the application across both dev and QA.

**Steps**:

1. **Create** GitOps configuration for QA environment on your Arc cluster
   - [ ] Export your cluster details as environment variables
   - [ ] Run `az k8s-configuration flux create` command targeting the `west-us` path in `kalypso-platform-gitops` repository
   - **Pro tip**: The path parameter determines which cluster type assignments this cluster receives
   - [ ] Verify configuration created successfully in Azure portal
   - **Pro tip**: The GitOps configurations (platform-dev and platform-qa) will show as "Non-Compliant" until you promote the application in the next steps - this is expected because application manifests don't exist in the gitops repository yet
   - [ ] **Expected result**: Arc cluster subscribed to west-us cluster type in QA

2. **Trigger** application CI/CD pipeline for initial deployment
   - [ ] Navigate to `basic-inference-orchestration` repository in GitHub
   - [ ] Review and merge the initial PR to trigger CI/CD workflow
   - **Pro tip**: The CI/CD workflow will first create a PR to the `dev` branch in the gitops repository. After successful deployment to dev, it will automatically create a PR to the `qa` branch
   - **Validation checkpoint**: Check the Actions tab - what steps does the workflow execute?
   - [ ] **Expected result**: GitHub Actions workflow triggered for application build and dev environment PR created

3. **Promote** application to dev and QA environments
   - [ ] Merge PR to `dev` branch in `basic-inference-orchestration-gitops` repository
   - [ ] Wait for Flux to sync application to dev environment (check Azure portal GitOps tab)
   - [ ] Verify pods running in `basic-inference-dev` namespace: `kubectl get pods -n basic-inference-dev`
   - **Pro tip**: After successful dev deployment, the CI/CD workflow automatically creates a PR to the `qa` branch
   - [ ] Merge PR to `qa` branch in `basic-inference-orchestration-gitops` repository (created after dev deployment)
   - [ ] Wait for Flux to sync application to QA environment
   - [ ] Verify pods running in `basic-inference-qa` namespace: `kubectl get pods -n basic-inference-qa`
   - **Success check**: Application running successfully in both environments on your Arc cluster

### Task 5: Implement Platform Configuration Management (20 minutes)

<!-- AI_COACH: Platform configuration demonstrates separation of concerns between application requirements and platform capabilities. Rather than showing the exact YAML structure, encourage learners to review the tutorial examples and understand how configuration schemas request platform services and how platform teams fulfill those requests. -->

**What You'll Do**: Configure platform-provided settings that applications consume across environments.

**Steps**:

1. **Request** platform configuration from the application team perspective
   - [ ] Navigate to `basic-inference-orchestration` repository and open `workload/workload.yaml`
   - [ ] Add `configSchemas` section declaring required platform configuration (e.g., `inference_url`)
   - **Pro tip**: Pay attention to YAML indentation - `configSchemas` should be at the same level as `deploymentTargets` under the `spec` section, not nested inside it
   - [ ] Update application code in `helm/templates/deployment.yaml` to consume from `platform-config` ConfigMap instead of application-specific ConfigMap
   - **Validation checkpoint**: What happens when you commit this change to the main branch?
   - [ ] Commit and push changes to trigger the configuration request
   - **Pro tip**: The control plane detects missing platform config and creates issues in platform-gitops repository
   - [ ] **Expected result**: Control plane creates issues requesting platform team to provide the configuration

2. **Define** platform configuration for the dev environment
   - [ ] Checkout `dev` branch in `kalypso-control-plane` repository
   - [ ] Create `configs/inference-config.yaml` with ConfigMap containing platform-specific settings
   - [ ] Add `inference_url` configuration value with label `component: inference`
   - **Validation checkpoint**: How does this configuration get composed into the platform-config ConfigMap?
   - [ ] Commit and push configuration to dev branch
   - [ ] **Expected result**: Platform configuration committed to control plane repository

3. **Verify** configuration propagation via PR
   - [ ] Wait for control plane to process configuration and create PR
   - [ ] Review PR in `kalypso-platform-gitops` repository showing updated platform-config
   - [ ] Merge PR to propagate configuration to dev clusters
   - **Pro tip**: Configuration issues in platform-gitops repository signal missing or invalid platform config
   - [ ] **Expected result**: Platform configuration merged and available to applications

4. **Implement** region-specific configuration for QA
   - [ ] Checkout `qa` branch in `kalypso-control-plane` repository
   - [ ] Create `configs/inference-config-east-us.yaml` with ConfigMap containing east-us specific settings (labels: `platform-config: "true"`, `component: inference`, `region: eastus`)
   - [ ] Create `configs/inference-config-west-us.yaml` with ConfigMap containing west-us specific settings (labels: `platform-config: "true"`, `component: inference`, `region: westus`)
   - [ ] Use different `inference_url` values for each region (e.g., `https://qa-eastus-api.contoso.com` and `https://qa-westus-api.contoso.com`)
   - **Pro tip**: You're creating configs for both regions as a complete platform configuration practice, but the PR will only reflect changes to west-us because that's the only region with an active workload assignment from your scheduling policy
   - **Validation checkpoint**: Why does the PR only update west-us/platform-config.yaml even though you created configs for both regions? (Hint: check which cluster types have workload assignments in Task 3)
   - [ ] Commit and push both configuration files to qa branch
   - [ ] Wait for control plane to create PR in `kalypso-platform-gitops` repository
   - [ ] Review PR - notice it only updates `west-us/platform-config.yaml` (not east-us) because only west-us has the workload assignment
   - [ ] Merge the resulting PR
   - [ ] **Expected result**: Both regional configs created in control plane, but platform-config only deployed to west-us cluster type due to scheduling policy assignment

## Completion Check

**You've Succeeded When**:

- [ ] Kalypso control plane deployed and managing multi-environment orchestration
- [ ] Application successfully registered and assigned to dev and QA cluster types
- [ ] Scheduling policies control application placement based on cluster labels
- [ ] Platform configurations provide environment and region-specific settings
- [ ] Application running in multiple namespaces on Arc cluster via GitOps
- [ ] Can explain the separation between application teams, platform teams, and cluster operators

**Next Steps**: Explore advanced orchestration patterns in production scenarios or integrate additional applications with the control plane.

---

## Cleanup Resources

**⚠️ IMPORTANT**: Complete cleanup within 3-4 hours of deployment to avoid ongoing Azure charges.

### Cleanup Steps

1. **Run** the automated cleanup script with your deployment parameters

   ```bash
   ./basic-inference-workload.sh \
     --cleanup \
     --org your-github-org \
     --arc-cluster your-arc-cluster \
     --arc-rg your-resource-group \
     --kalypso-cluster kalypso-control-plane \
     --kalypso-rg rg-kalypso-control \
     --kalypso-location eastus
   ```

2. **Verify** all resources were deleted

   ```bash
   # Check Azure resources
   az resource list --resource-group rg-kalypso-control --output table

   # Verify GitOps configurations removed from Arc cluster
   az k8s-configuration flux list \
     --cluster-name your-arc-cluster \
     --resource-group your-resource-group \
     --cluster-type connectedClusters \
     --output table
   ```

3. **Check** GitHub repositories were deleted
   - Navigate to your GitHub organization
   - Verify these repositories are removed:
     - `basic-inference-orchestration`
     - `basic-inference-orchestration-configs`
     - `basic-inference-orchestration-gitops`
     - `kalypso-control-plane`
     - `kalypso-platform-gitops`

### What Gets Deleted

**Azure Resources**:

- Kalypso AKS cluster (control plane)
- Resource group containing the Kalypso cluster
- GitOps configurations on Arc cluster (`platform-dev` and `platform-qa`)

**GitHub Resources**:

- All 5 repositories created by the setup script

**What's NOT Deleted**:

- Your Azure Arc cluster (only GitOps configurations are removed)
- Any other resources in the Arc cluster's resource group

### Troubleshooting Cleanup

**If cleanup script fails**:

1. Manually delete GitOps configurations first:

   ```bash
   # Delete dev environment configuration
   az k8s-configuration flux delete \
     --name platform-dev \
     --cluster-name your-arc-cluster \
     --resource-group your-resource-group \
     --cluster-type connectedClusters \
     --yes

   # Delete QA environment configuration (if created)
   az k8s-configuration flux delete \
     --name platform-qa \
     --cluster-name your-arc-cluster \
     --resource-group your-resource-group \
     --cluster-type connectedClusters \
     --yes
   ```

2. Manually delete application namespaces from Arc cluster:

   ```bash
   kubectl delete namespace basic-inference-dev
   kubectl delete namespace basic-inference-qa
   ```

3. Re-run the cleanup script

**If repositories aren't deleted**:

- Manually delete them from your GitHub organization settings
- The cleanup script uses GitHub CLI (`gh repo delete`)

**If AKS cluster deletion times out**:

- This is normal - deletion continues in the background
- Wait 5-10 minutes and verify in Azure Portal
- Check with: `az aks show --name kalypso-control-plane --resource-group rg-kalypso-control`

---

## Reference Appendix

### Help Resources

- **Tutorial Documentation**: Review `src/600-workload-orchestration/600-kalypso/basic-inference-workload-orchestration/README.md` for detailed explanations
- **Kalypso Documentation**: [Kalypso GitHub Repository](https://github.com/microsoft/kalypso) for architecture and concepts
- **Azure Arc GitOps**: [Workload Management Documentation](https://learn.microsoft.com/azure/azure-arc/kubernetes/conceptual-workload-management)
- **Learning Kata Coach**: Use for guided troubleshooting and concept clarification

### Professional Tips

- Always update GitHub organization placeholders (YOUR_ORG) in YAML files before committing
- Kalypso Scheduler processes changes immediately (seconds) - only main branch changes trigger CI/CD workflows that may take longer
- Use label selectors strategically to enable flexible application scheduling without tight coupling
- Monitor both control-plane and platform-gitops repositories for PR creation as validation
- Separate concerns: applications declare requirements, platform provides capabilities

### Troubleshooting

**Issue**: Control plane doesn't create PR after workload registration

- **Quick Fix**: Verify workload registration YAML syntax is correct and repository URL uses your GitHub org. Check Kalypso scheduler logs in `kalypso-system` namespace

**Issue**: Application pods not appearing in cluster namespace

- **Quick Fix**: Verify GitOps configuration exists for the environment, check Flux reconciliation status in Azure portal, ensure PR merged in platform-gitops repository

**Issue**: Platform configuration not available to application

- **Quick Fix**: Verify config has correct labels, check control plane processed config (look for PR in platform-gitops), ensure config merged to appropriate environment branch

**Issue**: Cleanup script fails to delete resources

- **Quick Fix**: See the "Cleanup Resources" section above for detailed troubleshooting steps. Manually delete GitOps configurations first using `az k8s-configuration flux delete`, then retry cleanup script

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
