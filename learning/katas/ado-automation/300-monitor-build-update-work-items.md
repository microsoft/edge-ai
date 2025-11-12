---
title: 'Kata: 300 - Monitor Build and Update Work Items'
description: Learn to track Azure DevOps pipeline builds and automatically update work items based on build status using MCP automation
author: Edge AI Team
ms.date: 2025-01-25
kata_id: ado-automation-300-monitor-build-update-work-items
kata_category:
  - ado-automation
kata_difficulty: 3
estimated_time_minutes: 35
learning_objectives:
  - Query Azure Pipelines build status programmatically
  - Update work items based on build success or failure
  - Implement automated work item comments for build tracking
prerequisite_katas:
  - ado-automation-300-link-work-items-to-pull-request
technologies:
  - Azure DevOps
  - MCP
  - Work Items
  - Azure Pipelines
  - CI/CD
  - GitHub Copilot
success_criteria:
  - Successfully query build status for PRs and branches
  - Update work items with build results automatically
ai_coaching_level: minimal
scaffolding_level: light
hint_strategy: conceptual
common_pitfalls: []
requires_azure_subscription: false
requires_local_environment: true
tags:
  - ado-automation
search_keywords:
  - pipeline-build-tracking
  - ci-cd-work-item-integration
  - build-status-automation
---

## Quick Context

**You'll Learn**: Integrate Azure Pipelines build monitoring with work item updates using MCP automation for CI/CD visibility.

**Real Challenge**: You're a release engineer at a healthcare technology company where teams need real-time visibility into build failures affecting their work items. Manual build monitoring and work item updates create communication delays. This kata teaches automated build tracking with work item status synchronization using GitHub Copilot and MCP.

## Essential Setup

**Required** (check these first):

- [ ] Visual Studio Code with GitHub Copilot extension installed
- [ ] Azure DevOps MCP server configured with PR/work item integration completed ([Kata 05](./300-link-work-items-to-pull-request.md) finished)
- [ ] Access to Azure Pipelines with at least one configured pipeline
- [ ] Active PR with linked work items and triggered pipeline build

**Quick Validation**: In Azure DevOps portal, confirm you can view pipeline builds for your repository.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** chat mode for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** mode and say:
>
> ```text
> I'm working on Monitor Build and Update Work Items kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Query Build Status for PR (12 minutes)

**What You'll Do**: Retrieve build status information for pull requests using MCP automation.

**Steps**:

1. **Identify** PR with active or completed build
   - [ ] Use an existing PR with linked work items from Kata 05
   - [ ] Note the PR ID and ensure it has triggered a pipeline build
   - [ ] Verify build status visible in Azure DevOps (running, succeeded, failed)
   - [ ] **Expected result**: PR with associated pipeline build identified

2. **Query** build status via MCP
   - [ ] Say: *"Using MCP, get the latest build status for pull request #[PRID]"*
   - [ ] Review build information returned: build ID, status, start time, duration
   - [ ] Note specific failure reasons if build failed
   - [ ] **Expected result**: Build status retrieved programmatically

3. **Analyze** build results
   - [ ] Say: *"Using MCP, get detailed build logs for build #[BuildID]"*
   - [ ] Identify key build stages (restore, build, test, publish)
   - [ ] Locate any error messages or test failures
   - **Success check**: Can pinpoint exact build failure cause from logs
   - [ ] **Expected result**: Build failure root cause identified

### Task 2: Update Work Items Based on Build Status (15 minutes)

**What You'll Do**: Automatically update work items when builds succeed or fail.

**Steps**:

1. **Update** work item on build success
   - [ ] Trigger a successful build (or use existing successful build)
   - [ ] Say: *"Using MCP, add comment to work item #[ID]: 'Build #[BuildID] succeeded, PR ready for review'"*
   - [ ] Verify comment appears in work item history with timestamp
   - **Pro tip**: Include build URL in comment for quick navigation
   - [ ] **Expected result**: Work item updated with build success notification

2. **Update** work item on build failure
   - [ ] Identify a failed build (or intentionally break a test to create one)
   - [ ] Say: *"Using MCP, add comment to work item #[ID]: 'Build #[BuildID] failed with error: [ErrorMessage], requires investigation'"*
   - [ ] Include specific error details from build logs
   - [ ] Consider adding a tag like "build-broken" to the work item
   - **Validation checkpoint**: Does work item clearly indicate build failure details?
   - [ ] **Expected result**: Work item flagged with build failure information

3. **Automate** status field updates
   - [ ] For failed builds, say: *"Using MCP, update work item #[ID] state to 'Active' with reason 'Build failure requires code fixes'"*
   - [ ] For successful builds after fixes, update state back to "Resolved"
   - [ ] Review work item history showing state transitions tied to builds
   - **Success check**: Work item state reflects current build health
   - [ ] **Expected result**: Work item lifecycle synchronized with CI/CD pipeline

### Task 3: Implement Build Monitoring Workflow (8 minutes)

**What You'll Do**: Design a repeatable workflow for build monitoring and work item updates.

**Steps**:

1. **Design** monitoring pattern
   - [ ] Define when to check build status (after PR creation, on schedule, on webhook)
   - [ ] Determine which work item fields to update (state, comments, tags)
   - [ ] Plan notification strategy for stakeholders on failures
   - [ ] **Expected result**: Build monitoring workflow documented

2. **Test** end-to-end workflow
   - [ ] Create new PR with work item link: *"Using MCP, create PR from 'feature/test-build' to 'main', link work item #[ID]"*
   - [ ] Wait for build to trigger and complete (or manually trigger)
   - [ ] Query build status: *"Using MCP, get build status for PR #[PRID]"*
   - [ ] Update work item based on result following your workflow pattern
   - **Validation checkpoint**: Can you execute the entire workflow in under 5 minutes?
   - [ ] **Expected result**: Complete build-to-work-item update cycle tested

3. **Document** workflow for team adoption
   - [ ] Create checklist: PR creation → Build trigger → Status query → Work item update
   - [ ] Include MCP commands for each step as templates
   - [ ] Share with team for feedback and refinement
   - **Success check**: Team members can follow workflow independently
   - [ ] **Expected result**: Repeatable build monitoring process established

## Completion Check

**You've Succeeded When**:

- [ ] Can query Azure Pipelines build status for PRs and branches
- [ ] Can update work items with build success/failure information
- [ ] Can implement automated comments linking builds to work items
- [ ] Understand CI/CD integration patterns for work item management

**Next Steps**: Proceed to [Kata: Small Feature Planning](./300-small-feature-planning.md) to learn end-to-end feature planning workflows, or explore advanced automation with Azure DevOps webhooks and event-driven work item updates.

---

## Reference Appendix

### Help Resources

- **Azure Pipelines API**: [Get build information](https://learn.microsoft.com/rest/api/azure/devops/build/builds)
- **Work Item Updates**: [Update work items programmatically](https://learn.microsoft.com/rest/api/azure/devops/wit/work-items)
- **GitHub Copilot**: Use for parsing build logs and extracting error messages

### Professional Tips

- Include build URLs in work item comments for one-click navigation
- Use work item tags like "build-broken" for quick filtering
- Update work item state transitions to reflect build health (Active for failures, Resolved for fixes)
- Consider webhook-based automation for real-time build status updates

### Troubleshooting

**Issue**: Cannot retrieve build status via MCP

- **Quick Fix**: Verify PAT token has `vso.build` scope, check build ID correct, confirm pipeline permissions

**Issue**: Build logs too large to parse

- **Quick Fix**: Focus on error/warning sections, use MCP to extract specific log ranges, filter by build stage

**Issue**: Work item updates lag behind build completion

- **Quick Fix**: Use build completion webhooks for real-time updates, implement polling for non-webhook scenarios

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
