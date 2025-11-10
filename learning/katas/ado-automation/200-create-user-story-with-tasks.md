---
title: 'Kata: 200 - Create User Story with Tasks'
description: Learn to create hierarchical Azure DevOps work items with parent-child relationships using MCP automation for user story decomposition
author: Edge AI Team
ms.date: 2025-01-25
kata_id: ado-automation-200-create-user-story-with-tasks
kata_category:
  - ado-automation
kata_difficulty: 2
estimated_time_minutes: 30
learning_objectives:
  - Create user story work items with proper structure
  - Establish parent-child relationships between stories and tasks
  - Decompose user stories into actionable task breakdowns
prerequisite_katas:
  - ado-automation-200-create-single-task
technologies:
  - Azure DevOps
  - MCP
  - Work Items
  - User Stories
  - GitHub Copilot
success_criteria:
  - Successfully create user stories with complete acceptance criteria
  - Create child tasks linked to parent user stories
ai_coaching_level: guided
scaffolding_level: medium-heavy
hint_strategy: progressive
common_pitfalls: []
requires_azure_subscription: false
requires_local_environment: true
tags:
  - ado-automation
search_keywords:
  - user-story-creation
  - hierarchical-work-items
  - parent-child-links
---

## Quick Context

**You'll Learn**: Create hierarchical Azure DevOps work items with user stories and child tasks using MCP automation.

**Real Challenge**: You're a product engineer at a retail organization where sprint planning requires decomposing user stories into actionable tasks. Manual work item hierarchy creation is repetitive and inconsistent. This kata walks you through automated user story creation with task decomposition using GitHub Copilot and MCP.

## Essential Setup

**Required** (check these first):

- [ ] Visual Studio Code with GitHub Copilot extension installed
- [ ] Azure DevOps MCP server configured and task creation practiced ([Kata 03](./200-create-single-task.md) completed)
- [ ] Access to Azure DevOps project with work item creation permissions
- [ ] Understanding of user story structure and acceptance criteria

**Quick Validation**: In Copilot Chat, say: *"Using MCP, show me the fields required for a User Story work item"* to verify MCP access.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** chat mode for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** mode and say:
>
> ```text
> I'm working on Create User Story with Tasks kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Create User Story with Acceptance Criteria (10 minutes)

**What You'll Do**: Create a complete user story work item with proper acceptance criteria and description.

**Steps**:

1. **Draft** user story details
   - [ ] Title: "As a user, I can reset my password via email"
   - [ ] Description: "Users need self-service password reset capability to reduce support tickets. Implement email-based password reset flow with security tokens."
   - [ ] Acceptance Criteria including **"User can request password reset from login page"**, **"Reset link sent via email expires after 1 hour"**, **"New password meets complexity requirements"**, **"User receives confirmation after successful reset"**
   - [ ] **Expected result**: Complete user story specification prepared

2. **Create** user story with MCP
   - [ ] In Copilot Chat, say: *"Using MCP, create a User Story work item with title 'As a user, I can reset my password via email', include description and acceptance criteria"*
   - [ ] Provide the description and 4 acceptance criteria from step 1
   - [ ] Note the user story ID returned (e.g., #12345)
   - **Pro tip**: User stories focus on user value, tasks focus on technical implementation
   - [ ] **Expected result**: User story created with ID returned

3. **Verify** user story details
   - [ ] Query the user story: *"Using MCP, get work item #[ID] details"*
   - [ ] Confirm all acceptance criteria are present and correctly formatted
   - [ ] Verify description explains the user need clearly
   - **Success check**: Story provides sufficient context for task decomposition
   - [ ] **Expected result**: User story complete and ready for task breakdown

### Task 2: Decompose Story into Child Tasks (12 minutes)

**What You'll Do**: Create child tasks linked to the parent user story with clear ownership.

**Steps**:

1. **Plan** task decomposition
   - [ ] Based on acceptance criteria, identify technical tasks — **"Implement password reset request API endpoint"**, **"Create email template with secure reset link"**, **"Build password reset form with validation"**, **"Add password complexity validation logic"**
   - [ ] Estimate effort for each task (2-4 hours each)
   - **Pro tip**: Each acceptance criterion may require one or more technical tasks
   - [ ] **Expected result**: Task breakdown planned with effort estimates

2. **Create** first child task
   - [ ] Say: *"Using MCP, create a Task work item: 'Implement password reset request API endpoint', Original Estimate 3 hours, link as child to User Story #[ParentID]"*
   - [ ] Replace `[ParentID]` with your user story ID from Task 1
   - [ ] Note the child task ID returned
   - **Pro tip**: MCP uses `wit_add_child_work_items` tool to create and link child tasks automatically
   - **Pro tip**: Parent-child linking creates backlog hierarchy visible in Azure Boards
   - [ ] **Expected result**: Task created and linked to parent story

3. **Create** remaining child tasks
   - [ ] Create task 2: "Create email template with secure reset link" (2 hours)
   - [ ] Create task 3: "Build password reset form with validation" (4 hours)
   - [ ] Create task 4: "Add password complexity validation logic" (2 hours)
   - [ ] Link all tasks as children to the parent user story
   - **Validation checkpoint**: Do all tasks together fulfill the user story acceptance criteria?
   - [ ] **Expected result**: All 4 child tasks created and linked

4. **Verify** parent-child relationships
   - [ ] Say: *"Using MCP, show all child work items for User Story #[ParentID]"*
   - [ ] Confirm all 4 tasks appear in the child list
   - [ ] Verify total estimated effort sums correctly (11 hours)
   - **Success check**: Complete task hierarchy visible in queries
   - [ ] **Expected result**: Parent-child relationships correctly established

### Task 3: Create Multi-Task User Story in One Operation (8 minutes)

**What You'll Do**: Create user story with multiple child tasks in a single automation workflow.

**Steps**:

1. **Plan** complete work item hierarchy
   - [ ] User Story: "As a user, I can view my order history"
   - [ ] Child Tasks including **"Create order history API endpoint"**, **"Design order history UI component"**, **"Add pagination for large order lists"**, **"Implement order detail drill-down"**
   - [ ] **Expected result**: Complete hierarchy planned

2. **Create** story and tasks together
   - [ ] Say: *"Using MCP, create a User Story 'As a user, I can view my order history' with 4 child tasks: [list task titles with estimates]"*
   - [ ] Provide all task details in one prompt
   - **Pro tip**: Batch operations reduce API calls and ensure consistency
   - [ ] **Expected result**: Story and all tasks created atomically

3. **Validate** complete hierarchy
   - [ ] Query the parent story and confirm all child tasks linked
   - [ ] Verify task titles and estimates match your plan
   - [ ] Check that story acceptance criteria align with task breakdown
   - **Success check**: Complete user story ready for sprint planning
   - [ ] **Expected result**: Functional work item hierarchy created efficiently

## Completion Check

**You've Succeeded When**:

- [ ] Can create user stories with complete acceptance criteria
- [ ] Can create child tasks linked to parent user stories
- [ ] Can decompose user stories into actionable task breakdowns
- [ ] Understand parent-child relationships in Azure DevOps work items

**Next Steps**: Proceed to [Kata: Link Work Items to Pull Request](./05-link-work-items-to-pull-request.md) to learn PR integration patterns.

---

## Reference Appendix

### Help Resources

- **User Story Guidance**: [Create user stories in Azure Boards](https://learn.microsoft.com/en-us/azure/devops/boards/work-items/guidance/agile-process-workflow)
- **Parent-Child Links**: [Link work items in Azure DevOps](https://learn.microsoft.com/en-us/azure/devops/boards/backlogs/add-link)
- **GitHub Copilot**: Use for generating task decompositions from user stories

### Professional Tips

- User stories should focus on user value, not technical implementation
- Each acceptance criterion should be independently testable
- Child tasks should collectively fulfill all parent acceptance criteria
- Estimate tasks in hours (2-8 hour range), stories in story points

### Troubleshooting

**Issue**: Parent-child link fails to create

- **Quick Fix**: Verify both work items exist, check link type is "Child" not "Related", confirm permissions

**Issue**: Task breakdown doesn't cover all acceptance criteria

- **Quick Fix**: Review each criterion, ensure at least one task addresses it, add missing tasks

**Issue**: User story too large to decompose into tasks

- **Quick Fix**: Split into multiple smaller user stories, each with focused scope

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
