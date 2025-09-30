---
mode: "agent"
description: "Analyze research, plans, or repository changes to discover and plan Azure DevOps User Stories and Bugs with handoff for creation or updates."
---

# Discover Work Items & Produce Handoff

Follow all instructions from #file:../instructions/ado-wit-discovery.instructions.md and #file:../instructions/ado-wit-planning.instructions.md

## Inputs

* ${input:adoProject:edge-ai}: Azure DevOps project identifier.
* ${input:witFocus:User Story}: Work item type to focus on (`User Story` or `Bug`). Determines which work items to discover, create, and update.
* ${input:documents}: (Optional) Comma-separated relative paths or attachments for source material (research, plans, details). Infer from conversation context when omitted.
* ${input:includeBranchChanges:false}: (Optional) Include git diff analysis for work item discovery when no documents are provided.
* ${input:baseBranch:origin/main}: (Optional) Git comparison base for diff and commit analysis.
* ${input:areaPath}: (Optional) Area Path filter for work item searches.
* ${input:iterationPath}: (Optional) Iteration Path filter for work item searches.
* ${input:workItemStates:New,Active,Resolved}: (Optional) Comma-separated states to include in searches.

## Instructions

Analyze provided artifacts and repository changes to:

1. Discover existing work items of type `${input:witFocus}` in Azure DevOps.
2. Update existing work items when they align with the work being requested.
3. Create minimal new work items (prefer one unless work is large or involves multiple contributors).
4. When `${input:witFocus}` is `User Story`, link to existing parent Features and Epics for traceability.
5. When `${input:witFocus}` is `Bug`, skip parent linking (Bugs are standalone).
6. Produce a handoff document for execution.

**Feature and Epic discovery**: When working with User Stories, discover Features and Epics only for linking purposes. Create or update Features and Epics only when explicitly requested by the user. When working with Bugs, skip Feature and Epic discovery entirely.

Proceed through the discovery workflow. Update planning-log.md after each major action and maintain all planning files per the instructions.
