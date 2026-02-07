---
title: 'Kata: 200 - Create Single Task'
description: Learn to create individual Azure DevOps task work items using MCP automation with proper field population and validation
author: Edge AI Team
ms.date: 2025-01-25
kata_id: ado-automation-200-create-single-task
kata_category:
  - ado-automation
kata_difficulty: 2
estimated_time_minutes: 25
learning_objectives:
  - Create task work items with required and optional fields
  - Populate acceptance criteria and descriptions effectively
  - Validate task creation and verify field values
prerequisite_katas:
  - ado-automation-100-single-work-item-discovery
technologies:
  - Azure DevOps
  - MCP
  - Work Items
  - Task Creation
  - GitHub Copilot
success_criteria:
  - Successfully create tasks with all required fields populated
  - Validate task creation through query and verification
ai_coaching_level: guided
scaffolding_level: heavy
hint_strategy: progressive
common_pitfalls: []
requires_azure_subscription: false
requires_local_environment: true
tags:
  - ado-automation
search_keywords:
  - task-creation
  - work-item-automation
  - mcp-work-items
---

## Quick Context

**You'll Learn**: Create Azure DevOps task work items programmatically using MCP automation for efficient task management.

**Real Challenge**: You're a DevOps engineer at a logistics provider where manual task creation for sprint planning is time-consuming and error-prone. Your team needs automated task creation to standardize work item structure and reduce overhead. This kata walks you through MCP-powered task creation using GitHub Copilot.

## Essential Setup

**Required** (check these first):

- [ ] Visual Studio Code with GitHub Copilot extension installed
- [ ] Azure DevOps MCP server configured ([Kata 01](./100-configure-mcp-server.md) completed)
- [ ] Work item discovery patterns practiced ([Kata 02](./100-single-work-item-discovery.md) completed)
- [ ] Access to Azure DevOps project with work item creation permissions

**Quick Validation**: In Copilot Chat, say: *"Using MCP, show me the fields required to create a Task work item"* to verify MCP access.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on Create Single Task kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Create Basic Task with Required Fields (8 minutes)

**What You'll Do**: Create a simple task work item with only required fields populated.

**Steps**:

1. **Prepare** task details
   - [ ] Choose a task title: "Configure monitoring dashboard"
   - [ ] Choose area path from your project (use default if unsure)
   - [ ] Choose iteration path or use current sprint
   - [ ] **Expected result**: Task metadata ready for creation

2. **Create** task using MCP
   - [ ] In GitHub Copilot Chat, say: *"Using MCP, create a Task work item with title 'Configure monitoring dashboard', assigned to me, in area [YourArea]"*
   - [ ] Replace `[YourArea]` with your actual area path
   - [ ] Review the created task ID returned by MCP
   - **Pro tip**: "Assigned to me" uses your authenticated user identity from MCP login automatically
   - **Pro tip**: MCP automatically sets work item type, state defaults to "New"
   - [ ] **Expected result**: Task created with work item ID returned

3. **Verify** task creation
   - [ ] Say: *"Using MCP, get work item #[ID] details"*
   - [ ] Replace `[ID]` with the task ID from step 2
   - [ ] Confirm Title, Area Path, and Assigned To fields are correct
   - **Success check**: All required fields match your input
   - [ ] **Expected result**: Task details verified through query

### Task 2: Create Task with Description and Acceptance Criteria (10 minutes)

**What You'll Do**: Create a fully-detailed task including description, acceptance criteria, and tags.

**Steps**:

1. **Draft** task details
   - [ ] Title: "Implement authentication middleware"
   - [ ] Description: "Add JWT token validation middleware to API gateway. Support both Azure AD and API key authentication methods."
   - [ ] Acceptance Criteria including **"JWT tokens validated with correct signature"**, **"Azure AD integration tested"**, **"API key fallback works for service accounts"**
   - [ ] Tags: "authentication", "api-gateway"
   - [ ] **Expected result**: Complete task specification prepared

2. **Create** detailed task with MCP
   - [ ] In Copilot Chat, say: *"Using MCP, create a Task work item with these details:"* then provide — Title, Description, Acceptance Criteria (as list), Tags
   - [ ] Review the returned task ID
   - **Pro tip**: Use clear formatting in prompts - MCP understands structured lists
   - [ ] **Expected result**: Task created with all fields populated

3. **Verify** field population
   - [ ] Query the new task ID and verify these fields are correctly populated and formatted — **Description** (contains authentication details), **Acceptance Criteria** (shows all 3 items), **Tags** (contains both tags)
   - **Validation checkpoint**: Does the task have sufficient detail for another engineer to start work?
   - [ ] **Expected result**: All fields correctly populated and formatted

### Task 3: Create Task with Priority and Effort (7 minutes)

**What You'll Do**: Create task with priority ranking and effort estimation fields.

**Steps**:

1. **Define** task with estimates
   - [ ] Title: "Optimize database query performance"
   - [ ] Priority: 2 (High)
   - [ ] Original Estimate: 8 hours
   - [ ] Activity: Development
   - **Pro tip**: Priority scale: 1=Critical, 2=High, 3=Medium, 4=Low
   - [ ] **Expected result**: Task with priority and effort defined

2. **Create** task with estimation fields
   - [ ] Say: *"Using MCP, create a Task: 'Optimize database query performance', Priority 2, Original Estimate 8 hours, Activity=Development"*
   - [ ] Note the task ID returned
   - **Pro tip**: Effort estimates help with sprint capacity planning
   - [ ] **Expected result**: Task created with priority and estimation

3. **Validate** estimation fields
   - [ ] Query the task by ID
   - [ ] Verify Priority = 2
   - [ ] Confirm Original Estimate = 8 hours
   - [ ] Check Activity = Development
   - **Success check**: Task ready for sprint planning with effort estimates
   - [ ] **Expected result**: All estimation fields correctly set

## Completion Check

**You've Succeeded When**:

- [ ] Can create basic tasks with required fields only
- [ ] Can create detailed tasks with description, acceptance criteria, and tags
- [ ] Can create tasks with priority and effort estimation fields
- [ ] Can verify task creation through MCP queries

**Next Steps**: Proceed to [Kata: Create User Story with Tasks](./200-create-user-story-with-tasks.md) to learn hierarchical work item creation.

---

## Reference Appendix

### Help Resources

- **Azure DevOps Work Item Fields**: [Work item field index](https://learn.microsoft.com/azure/devops/boards/work-items/guidance/work-item-field)
- **Task Work Item Type**: [Tasks in Azure Boards](https://learn.microsoft.com/azure/devops/boards/backlogs/add-tasks)
- **GitHub Copilot**: Use for generating task descriptions and acceptance criteria

### Professional Tips

- Always include acceptance criteria for clarity and testability
- Use tags consistently across projects for filtering and reporting
- Set Original Estimate during creation for accurate sprint planning
- Priority 1 (Critical) should be reserved for production issues

### Troubleshooting

**Issue**: Task creation fails with "missing required field"

- **Quick Fix**: Verify Title and Area Path provided, check project settings for custom required fields

**Issue**: Acceptance criteria not formatted correctly in created task

- **Quick Fix**: Use numbered list format in prompt, verify field name is "Acceptance Criteria" (not "AC")

**Issue**: Tags not appearing in created task

- **Quick Fix**: Use comma-separated format, verify spelling matches existing tags in project

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
