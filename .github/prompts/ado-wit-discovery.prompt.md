---
mode: "agent"
description: "Analyze research, plans, or repo changes to discover Azure DevOps Features and User Stories, then produce a planning handoff."
---

# Discover Work Items & Produce Handoff

Follow all instructions from #file:../instructions/ado-wit-discovery.instructions.md and #file:../instructions/ado-wit-planning.instructions.md as authoritative guidance. When searching Azure DevOps, always include work items in `New`, `Active`, or `Resolved` state for Epics, Features, and User Stories unless the user provides a different set of states.

## Document Handling

* Evaluate every user-supplied attachment or referenced file together when determining which work items to discover, create, or update.
* When reviewing research documents, pull only the details that align with the tasks the user wants executed, and consolidate related tasks into a single User Story when they represent a unified outcome.

## Discovery-Only Mode

* If `${input:discoverUserStoriesOnly}` is `true`, operate in discovery-only mode: do not propose new work items or updates.
* Focus searches on existing User Stories in `New`, `Active`, or `Resolved` state that most closely match the provided context and record them without modifying their content.
* Ensure handoff entries note `No Change` for every referenced work item when operating in this mode and add related links to any resolved stories that inform new or updated work.

## Inputs

* ${input:adoProject:edge-ai}: Azure DevOps project identifier (override when the user requests a different project).
* ${input:planningType:changes}: Planning type folder name (e.g., research, plan, details, changes).
* ${input:researchDocuments}: (Optional) Comma-separated relative paths or attachments for research sources. Infer from provided context or attachments when omitted.
* ${input:taskPlan}: (Optional) Relative path to task plan instructions. Detect automatically from conversation if not supplied explicitly.
* ${input:taskDetails}: (Optional) Relative path to task detail notes. Identify from user-provided context or fallback artifacts when missing.
* ${input:discoverUserStoriesOnly:false}: (Optional) Enable discovery-only mode to surface matching User Stories without creating or updating work items.
* ${input:areaPath}: (Optional) Area Path filter for discovery.
* ${input:iterationPath}: (Optional) Iteration Path filter for discovery.
* Guidance may be provided directly through the conversation; capture all parent Feature/Epic directions and creation requests when given.
* Implicit change context (diffs, commits) must be gathered when none of the document inputs are provided.
* ${input:baseBranch:origin/main}: Git comparison base used for diffs and commit analysis when inspecting repository changes.

---

Proceed through the instructions in order. Update the planning-log task list after each major action and do not skip required protocol steps.
