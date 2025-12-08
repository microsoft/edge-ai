---
title: 'Kata: 300 - GitOps CI/CD Pipeline'
description: Learn to implement multi-environment GitOps CI/CD pipelines for edge applications using Helm, GitHub Actions, and Azure Arc Flux
author: Edge AI Team
ms.date: 2025-11-26
kata_id: edge-deployment-300-gitops-cicd-pipeline
kata_category:
  - edge-deployment
kata_difficulty: 3
estimated_time_minutes: 90
learning_objectives:
  - Implement GitOps CI/CD pipeline using the Kalypso promotional flow pattern
  - Configure automated build and deployment workflows for edge applications
  - Set up multi-environment promotion with PR-based approvals (dev→qa)
  - Integrate Azure Arc Flux for continuous deployment to edge clusters
prerequisite_katas:
  - edge-deployment-100-deployment-basics
technologies:
  - GitOps
  - GitHub Actions
  - Helm
  - Azure Arc
  - Flux
  - Kubernetes
success_criteria:
  - Successfully deploy complete CI/CD pipeline with source, config, and GitOps repositories
  - Implement automated build workflow that triggers on code changes
  - Configure multi-environment promotion flow from dev to qa
  - Validate application deployment via Flux GitOps on Arc cluster
ai_coaching_level: guided
scaffolding_level: medium
hint_strategy: progressive
common_pitfalls:
  - Not waiting for Flux to sync after merging GitOps PR
  - Forgetting to set required environment variables (TOKEN, AZURE_CREDENTIALS_SP)
  - Merging deployment PR before reviewing generated manifests
  - Not verifying Azure Arc GitOps configuration status in portal
requires_azure_subscription: true
requires_local_environment: true
tags:
  - edge-deployment
search_keywords:
  - gitops-cicd
  - kubernetes-deployment
  - helm-charts
  - github-actions
  - flux-cd
  - multi-environment
---

## Quick Context

**You'll Learn**: Implement a complete GitOps CI/CD pipeline for edge applications using the Kalypso promotional flow pattern with automated builds, environment-based configurations, and PR-driven deployments.

**Real Challenge**: As an application developer at a manufacturing company, you develop edge applications deployed across multiple factory sites. Manual deployments cause inconsistencies between dev and production environments, leading to configuration drift and deployment failures. You need an automated pipeline that builds once, promotes through environments with proper validation, and deploys consistently across distributed edge clusters.

**Your Task**: Set up a GitOps CI/CD pipeline that automates the build-deploy-promote cycle, uses separate repositories for code, configuration, and deployment manifests, and leverages Azure Arc Flux for continuous deployment.

## Essential Setup

- [ ] VS Code with GitHub Copilot and repository cloned at `/src/501-ci-cd/basic-inference-cicd/`
- [ ] Azure Arc-enabled Kubernetes cluster connected and accessible via kubectl
- [ ] Azure CLI and GitHub CLI authenticated (`az login` and `gh auth status`)
- [ ] GitHub Personal Access Token with required scopes (repo, workflow, packages, admin)
- [ ] Environment variables set: `TOKEN` and `AZURE_CREDENTIALS_SP` (service principal JSON)
- [ ] Budget allocated: **$30-50 USD** | ⏱️ **90 minutes** (setup, deployment, validation, cleanup)

**Quick Validation**: Run `az connectedk8s show --name <cluster> --resource-group <rg>` to verify Arc connection and `kubectl cluster-info` to confirm cluster access.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** chat mode for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** mode and say:
>
> ```text
> I'm working on 300 - GitOps CI/CD Pipeline kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Deploy CI/CD Infrastructure (20 minutes)

<!-- AI_COACH: This phase establishes the three-repository GitOps pattern. If learners struggle understanding the repository separation, guide them to think about concerns: source code changes, environment-specific config, and deployment state. The setup script automates creation, but understanding the structure is crucial for troubleshooting. -->

**What You'll Do**: Deploy the complete CI/CD pipeline infrastructure including source, config, and GitOps repositories.

**Steps**:

1. **Navigate** to the CI/CD setup directory and review architecture
   - [ ] Change to CI/CD directory: `cd src/501-ci-cd/basic-inference-cicd/`
   - [ ] Read the README to understand the three-repository pattern
   - **Validation checkpoint**: Can you explain why source, config, and GitOps repos are separate?
   - [ ] **Expected result**: Understanding of repository separation and the promotional flow

2. **Execute** the setup script with your cluster parameters
   - [ ] Run setup command with your specific values:

   ```bash
   ./basic-inference-cicd.sh \
     --org your-github-org \
     --project my-inference-pipeline \
     --cluster your-arc-cluster \
     --rg your-resource-group
   ```

   - [ ] Monitor script execution for repository creation and Flux configuration
   - **Pro tip**: The script creates 3 repos, configures 2 Flux instances (dev and qa), and sets up GitHub Actions secrets
   - [ ] **Expected result**: Script completes with all repositories created and Flux configurations deployed

3. **Verify** infrastructure deployment
   - [ ] Check GitHub organization for three new repositories (source, configs, gitops)
   - [ ] Verify Azure Arc cluster has two Flux configurations in Azure Portal (dev and qa)
   - [ ] Run `kubectl get gitrepositories,kustomizations -n flux-system` to see Flux resources
   - **Success check**: All repositories exist, Flux configurations active, no error messages

### Task 2: Trigger Build and Deploy Workflow (25 minutes)

<!-- AI_COACH: The initial PR contains GitHub Actions workflows. Rather than just merging it, encourage learners to explore the workflow files to understand the CI/CD orchestration. Ask them to trace the flow: what triggers the build, how does it promote to dev, what generates the manifests? -->

**What You'll Do**: Trigger the automated build pipeline and understand the CI/CD workflow orchestration.

**Steps**:

1. **Review** the initial PR with CI/CD workflows
   - [ ] Navigate to the source repository and open the initial pull request
   - [ ] Examine the workflow files in `.github/workflows/` directory
   - **Validation checkpoint**: What triggers the `ci` workflow? What does the `deploy` workflow do?
   - [ ] Review the tools directory to understand manifest generation
   - [ ] **Expected result**: Understanding of workflow triggers and actions

2. **Merge** the PR to trigger the CI workflow
   - [ ] Merge the initial PR to the main branch
   - [ ] Navigate to Actions tab to watch the `ci` workflow execute
   - [ ] Monitor Docker image build and push to GitHub Packages
   - **Pro tip**: The `ci` workflow automatically triggers `deploy` workflow at completion
   - [ ] **Expected result**: CI workflow completes successfully, deploy workflow initiated

3. **Review** the deployment PR to dev environment
   - [ ] Open the GitOps repository and check for PR to `dev` branch
   - [ ] Examine the generated Kubernetes manifests (deployment, service, configmap)
   - [ ] Verify manifest values match dev environment configuration
   - **Validation checkpoint**: Where did the configuration values come from?
   - [ ] **Expected result**: Understanding of how Helm templates + config values generate manifests

### Task 3: Deploy to Dev Environment (20 minutes)

<!-- AI_COACH: Deployment happens in two stages: PR merge (intent) and Flux sync (execution). If learners don't see pods immediately after merging, guide them to check Flux reconciliation status rather than assuming failure. The Azure Portal GitOps view provides excellent visibility into sync progress. -->

**What You'll Do**: Deploy the application to the dev environment and verify Flux GitOps synchronization.

**Steps**:

1. **Merge** the deployment PR to initiate dev deployment
   - [ ] Review the manifests one final time in the GitOps PR
   - [ ] Merge the PR to the `dev` branch of the GitOps repository
   - **Pro tip**: Merging represents deployment approval; Flux handles actual deployment
   - [ ] **Expected result**: PR merged, Flux begins synchronization

2. **Monitor** Flux deployment progress
   - [ ] Open Azure Portal and navigate to your Arc cluster's GitOps tab
   - [ ] Watch the dev Flux configuration sync status
   - [ ] Run `kubectl get all -n dev-<project-name>` to see resources being created
   - **Validation checkpoint**: What happens if a manifest has an error? Does Flux stop or continue?
   - [ ] **Expected result**: Application pods running, services created, GitOps shows "Compliant"

3. **Validate** application deployment
   - [ ] Check pod status: `kubectl get pods -n dev-<project-name>`
   - [ ] Wait for all pods to be ready: `kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=basic-inference --timeout=300s -n dev-<project-name>`
   - [ ] Run the e2e test job: `kubectl apply -f src/500-application/500-basic-inference/tests/e2e-test-job.yaml -n dev-<project-name>`
   - [ ] Wait for test completion: `kubectl wait --for=condition=complete job/e2e-test --timeout=300s -n dev-<project-name>`
   - [ ] View test logs: `kubectl logs job/e2e-test -n dev-<project-name>`
   - [ ] Clean up test job: `kubectl delete job e2e-test -n dev-<project-name>`
   - **Success check**: E2e test completes successfully, all pods healthy

### Task 4: Promote to QA Environment (15 minutes)

<!-- AI_COACH: Promotion is triggered by successful deployment, not by merging code. The post-deployment workflow monitors cluster state via Azure Arc and only promotes when dev deployment succeeds. If promotion doesn't trigger, guide learners to check the GitOps compliance status in Azure Portal. -->

**What You'll Do**: Observe automated promotion to QA environment after successful dev deployment.

**Steps**:

1. **Monitor** automatic promotion trigger
   - [ ] Watch the `post-deployment` workflow in the source repository Actions tab
   - [ ] Observe it waiting for dev deployment success via Azure Arc status
   - **Validation checkpoint**: How does the workflow know deployment succeeded?
   - [ ] Wait for `deploy` workflow to trigger for QA environment
   - [ ] **Expected result**: Deploy workflow creates PR to `qa` branch in GitOps repo

2. **Review** QA deployment PR
   - [ ] Open the PR to `qa` branch in the GitOps repository
   - [ ] Compare QA manifests with dev manifests - note they're identical except for namespace
   - [ ] Verify namespace is `qa-<project-name>` (different from dev)
   - **Pro tip**: Initially, dev and qa config branches have identical values. The pattern enables environment-specific differences, but configs start the same
   - **Validation checkpoint**: What configuration values would you make different between dev and QA in a real scenario?
   - [ ] **Expected result**: Understanding that the three-repo pattern enables environment-specific configs, even though they start identical

3. **Deploy** to QA environment
   - [ ] Merge the QA deployment PR
   - [ ] Monitor Flux sync in Azure Portal for QA environment
   - [ ] Verify pods running: `kubectl get pods -n qa-<project-name>`
   - [ ] Test QA endpoint to confirm deployment
   - **Success check**: Application running in both dev and qa namespaces

### Task 5: Update Configuration and Redeploy (10 minutes)

<!-- AI_COACH: Configuration changes bypass the build stage since the container image doesn't change. Encourage learners to think about the workflow path: config change → manifest regeneration → deployment. No new Docker build occurs. This demonstrates the separation between code changes and configuration changes. -->

**What You'll Do**: Update environment-specific configuration and observe selective redeployment.

**Steps**:

1. **Modify** dev environment configuration
   - [ ] Navigate to the configs repository and checkout `dev` branch
   - [ ] Edit `values.yaml` to increase CPU requests (e.g., from `20m` to `50m`) or change replicas (e.g., from `1` to `2`)
   - [ ] Commit and push the configuration change
   - **Validation checkpoint**: Will this change affect the qa environment?
   - [ ] **Expected result**: Configuration change committed to dev branch

2. **Monitor** configuration deployment workflow
   - [ ] Watch the `deploy` workflow trigger in source repository
   - [ ] Observe that no `ci` workflow runs (no code change)
   - [ ] Review the PR created to `dev` branch of GitOps repository
   - **Pro tip**: Notice only dev manifests regenerated, qa unchanged
   - [ ] **Expected result**: New PR with updated configuration for dev only

3. **Apply** configuration change
   - [ ] Merge the configuration deployment PR
   - [ ] Monitor Flux applying the configuration change
   - [ ] Verify updated configuration: `kubectl describe deployment -n dev-<project-name>`
   - [ ] Confirm qa environment unchanged: `kubectl get deployment -n qa-<project-name>`
   - **Success check**: Dev configuration updated, qa remains stable

## Completion Check

**You've Succeeded When**:

- [ ] Complete CI/CD pipeline deployed with three-repository GitOps pattern
- [ ] Automated build workflow triggers on code changes and publishes container images
- [ ] Multi-environment promotion flow (dev→qa) works with PR-based approvals
- [ ] Flux GitOps continuously deploys from GitOps repository to Arc cluster
- [ ] Configuration changes deploy to specific environments without rebuilding
- [ ] Can trace the flow from code commit to production deployment

**Next Steps**: Explore workload orchestration with Kalypso or implement compliance validation in the pipeline.

---

## Cleanup Resources

**⚠️ IMPORTANT**: Complete cleanup within 2-3 hours of deployment to avoid ongoing charges.

### Cleanup Steps

1. **Run** the automated cleanup script

   ```bash
   ./basic-inference-cicd.sh \
     --cleanup \
     --org your-github-org \
     --project my-inference-pipeline \
     --cluster your-arc-cluster \
     --rg your-resource-group
   ```

2. **Verify** resources deleted

   ```bash
   # Check Flux configurations removed
   az k8s-configuration flux list \
     --cluster-name your-arc-cluster \
     --resource-group your-resource-group \
     --cluster-type connectedClusters

   # Verify namespaces deleted
   kubectl get namespaces | grep -E "(dev|qa)-"
   ```

3. **Check** GitHub repositories removed
   - Verify `<project-name>`, `<project-name>-configs`, and `<project-name>-gitops` are deleted from your organization

### What Gets Deleted

**Azure Resources**:

- Flux configurations: `<project-name>-dev` and `<project-name>-qa`
- Kubernetes namespaces: `dev-<project-name>` and `qa-<project-name>`

**GitHub Resources**:

- Application source repository
- Application configs repository
- Application GitOps repository

**What's NOT Deleted**:

- Your Azure Arc cluster (only Flux configs and app namespaces removed)
- GitHub Packages (container images remain)

### Troubleshooting Cleanup

**If namespaces stuck in terminating state**:

```bash
# Force delete namespace
kubectl delete namespace dev-<project-name> --force --grace-period=0
kubectl delete namespace qa-<project-name> --force --grace-period=0
```

**If Flux configurations fail to delete**:

```bash
# Manually delete each configuration
az k8s-configuration flux delete \
  --name <project-name>-dev \
  --cluster-name your-arc-cluster \
  --resource-group your-resource-group \
  --cluster-type connectedClusters \
  --yes
```

**If GitHub repositories aren't deleted**:

- Manually delete from GitHub organization settings
- Check GitHub token has `delete_repo` scope

---

## Reference Appendix

### Help Resources

- **Tutorial Documentation**: Review `src/501-ci-cd/basic-inference-cicd/README.md` for detailed explanations
- **CI/CD ADR**: Read [CI/CD Multi-Environment GitOps ADR](../../../docs/solution-adr-library/cicd-gitops.md) for architecture decisions
- **Kalypso Documentation**: [Kalypso GitHub Repository](https://github.com/microsoft/kalypso) for pattern details
- **Flux Documentation**: [Flux CD Docs](https://fluxcd.io/docs/) for GitOps concepts
- **Learning Kata Coach**: Use for guided troubleshooting and concept clarification

### Professional Tips

- Always review generated manifests before merging deployment PRs
- Use Azure Portal GitOps tab for real-time deployment status visibility
- Separate configuration changes (no rebuild) from code changes (rebuild required)
- Monitor commit status in source repository to track promotion flow
- Environment-specific configs in separate branches prevent accidental cross-environment changes
- Flux reconciliation interval determines deployment delay after PR merge

### Troubleshooting

**Issue**: CI workflow fails to build Docker image

- **Quick Fix**: Check GitHub Actions logs for authentication errors. Verify `AZURE_CREDENTIALS_SP` secret is set correctly in repository settings. Ensure GitHub Packages has write permissions

**Issue**: Deployment PR not created after CI completes

- **Quick Fix**: Check `deploy` workflow logs in source repository. Verify configs repository exists with correct branch structure. Ensure TOKEN has workflow scope

**Issue**: Flux not deploying after merging GitOps PR

- **Quick Fix**: Check Flux configuration status in Azure Portal. Run `kubectl logs -n flux-system deployment/kustomize-controller` for errors. Verify GitRepository resource can access GitHub repo

**Issue**: Pods in CrashLoopBackOff after deployment

- **Quick Fix**: Check pod logs with `kubectl logs -n <namespace> <pod-name>`. Verify ConfigMap values are correct. Check resource requests don't exceed cluster capacity

**Issue**: Promotion to QA not triggering

- **Quick Fix**: Verify dev deployment shows "Compliant" in Azure Portal GitOps tab. Check `post-deployment` workflow didn't fail. Ensure Azure Arc reporting is enabled

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
