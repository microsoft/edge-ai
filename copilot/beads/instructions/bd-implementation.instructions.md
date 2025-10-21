---
description: 'Required instructions when working with Beads tools when making edits.'
---
# Beads Implementation Instructions

Track all work in Beads instead of Markdown.

* Beads track epics/features/tasks/bugs/chores also known as bead issues or just issues or beads.
* All upcoming work, tracked work, issues, plans, task lists, memory for future or prior work, must always use the mcp_beads tools.

## Scope and Purpose

* Use `mcp_beads_*` tools to gather, update, and complete beads during and for implementation work.
* Apply these instructions whenever you implement code guided by ready or in-progress Beads issues.
* Combine these requirements with the technology-specific standards in `copilot/**` and `.github/instructions/**` that apply to the files you edit.

## Tooling Rules

* Operate exclusively through MCP tooling when managing Beads work; never rely on git, shell, or editor commands to change issue state.
* Use read-only workspace tools such as `read_file` and `search` to pull in required instruction files and cite them in your notes when they influence implementation decisions.

## Discover and Prioritize Work

* Call `mcp_beads_ready` to identify unblocked issues, if nothing is ready, inspect candidates with `mcp_beads_list({ status: 'open' })`.
* Use `mcp_beads_show` to confirm each issue's design notes, acceptance criteria, labels, and dependencies before writing code.
* When multiple issues are available, prefer lowest `priority` values first and honor `blocks` or `parent-child` relationships revealed by `mcp_beads_show`.

## Claim and Track Progress

1. Retrieve the full issue object via `mcp_beads_show` and read all embedded context.
2. Review any related beads as-needed for additional contextual details.
3. Claim the work by moving the status to `in_progress`, setting `assignee`, and recording a start note.

## Implement with Embedded Context

* Follow the file paths, schemas, validation commands, and conventions provided inside the issue’s `design` and `acceptance_criteria` fields
* Read additional files when the bead references files explicitly for contextual details.
* Read all relevant instruction files before editing code.
* While editing files, keep notes current with `mcp_beads_update({ issue_id, notes })` so that reasoning and partial progress remain captured.

## Record Newly Discovered Work

* When new issues surface, create these as beads immediately with `mcp_beads_create` and embed all necessary implementation context.
* When details for existing surface, update beads immediately with `mcp_beads_update` with details.
* Link discoveries back to the active issue using `mcp_beads_dep` with `dep_type: 'discovered-from'` and add any required `blocks` or `parent-child` relationships.
* Never create or update beads for creating tests or one-off scripts unless specifically requested through research or conversation.
* Never create or update beads for backwards compatibility or workarounds for potentially breaking changes. Breaking changes are always allowed.

## Maintain Dependencies and Readiness

* Capture dependency or priority changes with `mcp_beads_update` so downstream agents inherit the rationale and next steps.

## Communicate Status in Conversations

* Before starting work on a bead issue, provide a summary in the conversation the work that will be done.
* After completing work and marking the bead as closed:
  * Provide a summary of the work that was completed and any new work that was discovered that resulted in creating new beads.
  * Review all completed work and provide a high quality commit message to the user reading in and following all instructions provided by commit-message.instructions.md
  * Provide a summary of all open beads with their IDs and a short description.
  * Recommend the likely next bead to work on next and provide the ID, short detail, and short reason.
* When no open beads remain, suggest new work based to investigate for bead creation based on closed beads and the codebase.

## Complete and Close Work

Follow the Communicate Status in Conversations instructions and close the issue providing relevant details.

1. Execute every validation step documented in the issue’s acceptance criteria and ensure repository instructions for touched files are satisfied.
2. Update the issue notes with a brief summary of code changes, validations performed, and any follow-up references.
3. Close the issue with `mcp_beads_close`, specifying a descriptive reason that highlights the key modifications.
