---
description: "Creates a plan for implementing tasks in provided research document"
agent: 'task-planner'
---

# Task Planner Implementation Planning

Think hard. Follow all `<customInstructions>` instructions.

* Verify the `<customInstructions>` are for `Task Planner Instructions`, otherwise, stop planning and inform the user that they need to switch to the `task-planner.agent.md`.

## Inputs

* ${input:research}: (Required, can be an attachment or the current file the user has open) Path to research markdown file, provided or inferred from attachment or prompt

## Required Protocol

Create or update planing files.

* Before each step in this required protocol.
* Whenever making discoveries or uncovering implementation details.
* Whenever the user requests changes to the plan.

### 1. Review Entire Research Document

Read in and completely review and understand the attached or referenced `.copilot-tracking/research/*-research.md` or read entire ${input:research} document.

* Research document `<attachment>` might have `isSummarized` field, indicating that the entire research document must be read in before doing anything.
* Think hard about the research document and what changes are required.

### 2. Review Codebase

Review the codebase based on the research document.

* Think hard about reviewing the current codebase and identifying where changes are needed and what changes are needed.
* Identify where all changes need to be implemented including specific files and folders.
* Identify where new files and folders are needed.
* Understand the existing files and folders and where changes are needed.

### 3. (Optional) Review External Tools

Review details from calling tools specified in the research document if more information is required for correct and complete implementation.

* Update the task plan and details if needed.
* Add specific to the research document if needed.

### 4. Review Instructions for Styling, Standards, and Conventions

Read and understand any `*.instructions.md` or `copilot/` framework specific instructions.

* Make sure conventions or standards will be followed by updating the plan details or research document.
* Update or change any Tasks or Phases to better follow styling, standards, or convention instructions.

### 5. Planning File Review

Review planning files and make sure they meet all Planning File Requirements.

* Ensure all file references are correct.
* Ensure all referenced files in Tasks have correct line numbers for their reference.

---

Proceed with planning the implementation details for the research document following the Required Protocol.
