---
title: 'Kata: 100 - Discover Single Work Item'
description: Learn to query and discover individual Azure DevOps work items using MCP commands with ID-based lookup and title search patterns
author: Edge AI Team
ms.date: 2025-01-25
kata_id: ado-automation-100-single-work-item-discovery
kata_category:
  - ado-automation
kata_difficulty: 1
estimated_time_minutes: 23
learning_objectives:
  - Query work items by ID using MCP automation
  - Search work items by title and keywords
  - Filter work items by area path and work item type
prerequisite_katas:
  - ado-automation-100-configure-mcp-server
technologies:
  - Azure DevOps
  - MCP
  - Work Items
  - GitHub Copilot
success_criteria:
  - Successfully query work items by ID through MCP
  - Search and filter work items using title patterns and keywords
ai_coaching_level: guided
scaffolding_level: heavy
hint_strategy: progressive
common_pitfalls: []
requires_azure_subscription: false
requires_local_environment: true
tags:
  - ado-automation
search_keywords:
  - work-item-discovery
  - mcp-query-patterns
  - azure-devops-search
---

## Quick Context

**You'll Learn**: Discover and query Azure DevOps work items using MCP automation patterns for efficient work item management.

**Real Challenge**: You're a platform engineer at a manufacturing company where locating specific work items across large backlogs is time-consuming. Your team needs efficient discovery patterns to quickly find work items by ID, title, or area path. This kata walks you through MCP-powered work item discovery using GitHub Copilot.

## Essential Setup

**Required** (check these first):

- [ ] Visual Studio Code with GitHub Copilot extension installed
- [ ] Azure DevOps MCP server configured ([Kata 01](./100-configure-mcp-server.md) completed)
- [ ] Access to Azure DevOps project with existing work items
- [ ] At least 3-5 work items in your project for testing

**Quick Validation**: In Copilot Chat, say: *"Using MCP, count total work items in my Azure DevOps project"* to verify MCP connection.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on Discover Single Work Item kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 0: Establish Project Context (3 minutes)

**What You'll Do**: Identify your Azure DevOps project and verify access before querying work items.

**Steps**:

1. **List** available projects
   - [ ] Open GitHub Copilot Chat in VS Code (Agent Mode active)
   - [ ] Say: *"List ADO projects"*
   - [ ] Review the projects returned
   - **Pro tip**: Most work item tools require project context
   - [ ] **Expected result**: List of Azure DevOps projects you have access to

2. **Select** project for work
   - [ ] Choose a project from the list with existing work items
   - [ ] Note the project name for use in subsequent queries
   - [ ] If no work items exist, create 2-3 test tasks through Azure DevOps UI
   - **Success check**: Project identified with work items available for discovery
   - [ ] **Expected result**: Project context established for kata exercises

### Task 1: Query Work Item by ID (5 minutes)

**What You'll Do**: Retrieve specific work items using direct ID lookup.

**Steps**:

1. **Find** a work item ID
   - [ ] Open Azure DevOps in browser, navigate to your project from Task 0
   - [ ] Note the ID number of any existing work item (e.g., #12345)
   - [ ] Return to VS Code
   - [ ] **Expected result**: Work item ID identified for query

2. **Query** by ID using MCP
   - [ ] In GitHub Copilot Chat, say: *"Using MCP, get work item #[ID] details"*
   - [ ] Replace `[ID]` with your actual work item ID
   - [ ] Review returned fields: Title, State, Assigned To, Description
   - **Pro tip**: ID-based queries are fastest and most precise for known work items
   - [ ] **Expected result**: Complete work item details displayed

3. **Query** multiple IDs
   - [ ] Say: *"Using MCP, get details for work items #[ID1], #[ID2], #[ID3]"*
   - [ ] Compare the work item states and types
   - **Success check**: All requested work items returned in single query
   - [ ] **Expected result**: Bulk work item details retrieved efficiently

### Task 2: Search by Title and Keywords (8 minutes)

**What You'll Do**: Discover work items using title search and keyword patterns.

**Steps**:

1. **Search** by exact title match
   - [ ] In Copilot Chat, say: *"Using MCP, find work items with title containing 'bug' in my project"*
   - [ ] Review the matching work items
   - **Pro tip**: Title search is case-insensitive and supports partial matches
   - [ ] **Expected result**: Work items with "bug" in title displayed

2. **Search** using multiple keywords
   - [ ] Say: *"Using MCP, search work items with keywords 'deployment' OR 'infrastructure'"*
   - [ ] Examine how MCP returns items matching either keyword
   - **Validation checkpoint**: Do results include items with either keyword in title or description?
   - [ ] **Expected result**: Broader result set from multi-keyword search

3. **Refine** search with combined filters
   - [ ] Say: *"Using MCP, find open work items with 'API' in the title"*
   - [ ] Compare results to previous unfiltered searches
   - **Success check**: Results filtered by both state (open) and title keyword
   - [ ] **Expected result**: Focused result set matching multiple criteria

### Task 3: Filter by Area Path and Type (7 minutes)

**What You'll Do**: Apply area path and work item type filters for targeted discovery.

**Steps**:

1. **List** available area paths
   - [ ] In Copilot Chat, say: *"Using MCP, show me area paths available in this project"*
   - [ ] Note your project's area path structure
   - **Pro tip**: Area paths organize work hierarchically (e.g., Project\\Team\\Component)
   - [ ] **Expected result**: Area path tree displayed

2. **Filter** by area path
   - [ ] Say: *"Using MCP, find all work items in area path [YourAreaPath]"*
   - [ ] Replace `[YourAreaPath]` with an actual path from step 1
   - [ ] Review work items scoped to that area
   - **Validation checkpoint**: All returned items belong to specified area path
   - [ ] **Expected result**: Area-scoped work items retrieved

3. **Combine** area path and type filters
   - [ ] Say: *"Using MCP, find all Tasks in area path [YourAreaPath] with state 'Active'"*
   - [ ] Examine the filtered results
   - **Success check**: Results match all three criteria (type, area, state)
   - [ ] **Expected result**: Precise work item discovery using multiple filters

## Completion Check

**You've Succeeded When**:

- [ ] Can query work items by ID (single and bulk)
- [ ] Can search work items by title keywords
- [ ] Can filter work items by area path and work item type
- [ ] Understand how to combine multiple filter criteria for targeted discovery

**Next Steps**: Proceed to [Kata: Create Single Task](./200-create-single-task.md) to learn work item creation patterns.

---

## Reference Appendix

### Help Resources

- **Azure DevOps REST API**: [Work Items - Get](https://learn.microsoft.com/rest/api/azure/devops/wit/work-items/get-work-item)
- **Azure DevOps WIQL**: [Work Item Query Language](https://learn.microsoft.com/azure/devops/boards/queries/wiql-syntax)
- **GitHub Copilot**: Use for building complex query patterns

### Professional Tips

- Use ID-based queries for fastest retrieval when work item ID is known
- Combine filters to narrow large result sets efficiently
- Area paths are case-sensitive - verify exact spelling
- Title search supports wildcards and partial matches

### Troubleshooting

**Issue**: Work item query returns no results despite knowing items exist

- **Quick Fix**: Verify MCP connection active, check project selection, confirm work item IDs are correct

**Issue**: Area path filter fails with "path not found"

- **Quick Fix**: Use exact area path from project settings, verify path includes full hierarchy

**Issue**: Keyword search returns too many irrelevant results

- **Quick Fix**: Add state filter (e.g., "Active"), narrow with area path, use exact title phrases

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
