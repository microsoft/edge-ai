---
title: 'Kata: 300 - Small Feature Planning'
description: Learn to plan and create complete Azure DevOps work item hierarchies for small features using MCP automation
author: Edge AI Team
ms.date: 2025-01-25
kata_id: ado-automation-300-small-feature-planning
kata_category:
  - ado-automation
kata_difficulty: 3
estimated_time_minutes: 40
learning_objectives:
  - Create feature work items with user story decomposition
  - Build complete work item hierarchies (feature → stories → tasks)
  - Apply estimation and prioritization to planned work items
prerequisite_katas:
  - ado-automation-200-create-user-story-with-tasks
technologies:
  - Azure DevOps
  - MCP
  - Work Items
  - Features
  - Sprint Planning
  - GitHub Copilot
success_criteria:
  - Successfully create feature with child stories and grandchild tasks
  - Apply consistent estimation and prioritization across hierarchy
ai_coaching_level: minimal
scaffolding_level: light
hint_strategy: conceptual
common_pitfalls: []
requires_azure_subscription: false
requires_local_environment: true
tags:
  - ado-automation
search_keywords:
  - feature-planning
  - work-item-hierarchy
  - sprint-planning-automation
---

## Quick Context

**You'll Learn**: Plan and create complete Azure DevOps work item hierarchies for small features using MCP automation.

**Real Challenge**: You're a product owner at a logistics company where quarterly planning requires decomposing features into stories and tasks. Manual hierarchy creation for dozens of features is tedious and inconsistent. This kata teaches end-to-end feature planning with automated work item hierarchy creation using GitHub Copilot and MCP.

## Essential Setup

**Required** (check these first):

- [ ] Visual Studio Code with GitHub Copilot extension installed
- [ ] Azure DevOps MCP server configured and work item discovery practiced ([Kata 02](./100-single-work-item-discovery.md) completed)
- [ ] Access to Azure DevOps project with feature, user story, and task permissions
- [ ] Understanding of feature, epic, and backlog hierarchy concepts

**Quick Validation**: In Copilot Chat, say: *"Using MCP, show me the fields required for a Feature work item"* to verify MCP access.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** chat mode for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** mode and say:
>
> ```text
> I'm working on Small Feature Planning kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Create Feature with User Stories (15 minutes)

**What You'll Do**: Create a feature work item with child user stories decomposing the feature scope.

**Steps**:

1. **Plan** feature scope
   - [ ] Define feature: "Customer Notification System" for order status updates
   - [ ] Identify 3 user stories — **"As a customer, I receive email notifications for order status changes"**, **"As a customer, I can opt-in/opt-out of notifications via preferences"**, **"As a customer, I receive SMS notifications for critical order events"**
   - [ ] Draft feature description and business value
   - [ ] **Expected result**: Feature scope planned with story breakdown

2. **Create** feature work item
   - [ ] Say: *"Using MCP, create a Feature work item titled 'Customer Notification System' with description '[describe business value and scope]'"*
   - [ ] Note the feature ID returned (e.g., #5001)
   - [ ] Verify feature appears in backlog
   - **Pro tip**: Features represent significant business capabilities delivered over multiple sprints
   - [ ] **Expected result**: Feature work item created with ID

3. **Create** child user stories
   - [ ] Create Story 1: *"Using MCP, create User Story 'As a customer, I receive email notifications for order status changes', link as child to Feature #[FeatureID]"*
   - [ ] Create Story 2: "As a customer, I can opt-in/opt-out of notifications via preferences" (linked to feature)
   - [ ] Create Story 3: "As a customer, I receive SMS notifications for critical order events" (linked to feature)
   - [ ] Verify all stories appear as children of the feature
   - **Validation checkpoint**: Does each story deliver incremental value toward the feature?
   - [ ] **Expected result**: 3 user stories created and linked to feature

4. **Add** acceptance criteria to stories
   - [ ] For each story, say: *"Using MCP, update User Story #[ID] with acceptance criteria: [list criteria]"*
   - [ ] Story 1 criteria: "Email sent within 5 minutes of status change", "Email includes order details and tracking link"
   - [ ] Story 2 criteria: "Preference toggles for email/SMS available in profile", "Default opt-in status configurable"
   - [ ] Story 3 criteria: "SMS sent for shipment and delivery events", "SMS includes order number and brief status"
   - **Success check**: All stories have testable acceptance criteria
   - [ ] **Expected result**: User stories fully specified for development

### Task 2: Decompose Stories into Tasks (18 minutes)

**What You'll Do**: Break down each user story into technical implementation tasks.

**Steps**:

1. **Analyze** Story 1 technical requirements
   - [ ] Identify tasks needed — **"Create order status change event listener"**, **"Design email notification template"**, **"Implement email service integration (SendGrid/SMTP)"**, **"Add notification logging and error handling"**
   - [ ] Estimate each task (2-4 hours)
   - [ ] **Expected result**: Task breakdown for Story 1 planned

2. **Create** tasks for Story 1
   - [ ] Say: *"Using MCP, create 4 tasks for User Story #[Story1ID]: [list task titles with estimates], link all as children to story"*
   - [ ] Verify tasks appear as grandchildren of the feature
   - [ ] Check total story estimate matches sum of task estimates
   - **Pro tip**: Task granularity should allow completion within 1-2 days
   - [ ] **Expected result**: Story 1 fully decomposed into tasks

3. **Create** tasks for Story 2 and 3
   - [ ] Decompose Story 2 into 4 tasks: UI preference toggles, backend preference API, default configuration, integration testing
   - [ ] Decompose Story 3 into 5 tasks: SMS provider integration, event filtering logic, SMS template design, rate limiting, delivery confirmation
   - [ ] Create all tasks using MCP with proper parent-child links
   - [ ] Assign effort estimates to each task
   - **Validation checkpoint**: Do all tasks together deliver the feature completely?
   - [ ] **Expected result**: Complete 3-level hierarchy (Feature → Stories → Tasks)

4. **Review** complete hierarchy
   - [ ] Say: *"Using MCP, show all descendant work items for Feature #[FeatureID]"*
   - [ ] Verify hierarchy: 1 Feature → 3 Stories → 13 Tasks total
   - [ ] Check that total effort estimates sum correctly at each level
   - **Success check**: Complete work item hierarchy visible in Azure Boards
   - [ ] **Expected result**: Feature fully planned and ready for sprint assignment

### Task 3: Apply Estimation and Prioritization (7 minutes)

**What You'll Do**: Add story points, priorities, and iteration assignments to the hierarchy.

**Steps**:

1. **Estimate** user stories with story points
   - [ ] Story 1 (Email notifications): 8 story points (complex integration)
   - [ ] Story 2 (Preference management): 5 story points (moderate complexity)
   - [ ] Story 3 (SMS notifications): 13 story points (high complexity with new provider)
   - [ ] Say: *"Using MCP, update User Story #[ID] with Story Points [value]"* for each story
   - [ ] **Expected result**: All stories sized for sprint planning

2. **Prioritize** stories by business value
   - [ ] Set Story 1 priority to "1" (high - core functionality)
   - [ ] Set Story 2 priority to "2" (medium - usability enhancement)
   - [ ] Set Story 3 priority to "3" (lower - optional channel)
   - [ ] Say: *"Using MCP, update User Story #[ID] priority to [value]"* for each
   - **Pro tip**: Priority guides sprint selection when capacity is limited
   - [ ] **Expected result**: Stories prioritized for sequential delivery

3. **Assign** stories to iterations
   - [ ] Assign Story 1 to Sprint 1 (8 points, high priority)
   - [ ] Assign Story 2 to Sprint 1 if capacity allows, otherwise Sprint 2 (5 points)
   - [ ] Assign Story 3 to Sprint 2 or later (13 points, lower priority)
   - [ ] Say: *"Using MCP, assign User Story #[ID] to iteration '[Sprint Name]'"*
   - **Validation checkpoint**: Does sprint capacity accommodate assigned stories?
   - [ ] **Expected result**: Stories scheduled for implementation sprints

4. **Verify** feature completeness
   - [ ] Review feature work item to confirm all child stories linked
   - [ ] Check that feature acceptance criteria align with story acceptance criteria
   - [ ] Verify estimation totals: ~26 story points, ~40-50 hours task effort
   - **Success check**: Feature ready for development team assignment
   - [ ] **Expected result**: Complete feature plan ready for execution

## Completion Check

**You've Succeeded When**:

- [ ] Can create feature work items with child user stories
- [ ] Can build complete 3-level hierarchies (feature → stories → tasks)
- [ ] Can apply story point estimation and priority across hierarchy
- [ ] Understand sprint planning with work item hierarchies

**Next Steps**: You've completed the Azure DevOps Automation kata series! Explore advanced topics like automated sprint retrospectives, cross-project work item linking, or Azure Boards API integrations for custom dashboards.

---

## Reference Appendix

### Help Resources

- **Feature Planning**: [Organize work with features in Azure Boards](https://learn.microsoft.com/en-us/azure/devops/boards/backlogs/define-features-epics)
- **Story Points**: [Story point estimation guidance](https://learn.microsoft.com/en-us/azure/devops/boards/backlogs/create-your-backlog#estimates)
- **GitHub Copilot**: Use for decomposing features into stories and generating task breakdowns

### Professional Tips

- Features should represent significant capabilities, not individual code changes
- User stories should be deliverable within 1-2 sprints maximum
- Tasks should be completable in 1-2 days for accurate tracking
- Total story points for a feature typically range from 20-50 depending on complexity
- Use consistent estimation scales (Fibonacci: 1, 2, 3, 5, 8, 13, 21) across the team

### Troubleshooting

**Issue**: Hierarchy too deep (4+ levels)

- **Quick Fix**: Flatten hierarchy by consolidating tasks or splitting features, use epics for very large initiatives

**Issue**: Story point estimates don't match task hour estimates

- **Quick Fix**: Validate estimation consistency, adjust outliers, consider using only story points for high-level planning

**Issue**: Feature scope too broad for single release

- **Quick Fix**: Split into multiple features, use epic for multi-release initiatives, reduce story count per feature

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
