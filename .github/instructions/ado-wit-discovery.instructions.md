---
description: "Required protocol for discovering, planning, and handing off Azure DevOps Features and User Stories."
applyTo: '**/.copilot-tracking/workitems/**'
---

# Azure DevOps Work Item Discovery & Handoff

Follow all instructions from #file:./ado-wit-planning.instructions.md while executing this workflow.

## Scope

* Apply this procedure when research, plans, or repository changes must be translated into Azure DevOps Features or User Stories.
* Output lives under `.copilot-tracking/workitems/<planning-type>/<artifact-normalized-name>/` and includes `artifact-analysis.md`, `work-items.md`, `planning-log.md`, and `handoff.md`.
* Default Azure DevOps project derives from `${input:adoProject}`. Override only when the user provides a different project.

## Deliverables

* Planning workspace synchronized across `artifact-analysis.md`, `work-items.md`, and `planning-log.md` for every WI reference.
* `handoff.md` with Create actions listed before Update actions, each referencing supporting artifacts.
* ACTIVE KEYWORD GROUPS, similarity calculations, and decision notes logged in `planning-log.md`.
* Final conversational recap summarizing counts, parent decisions, unresolved reviews, and the planning folder path.

## Tooling

* `run_in_terminal` (zsh) for git context **only when no research documents or user direction are provided**:
   * `git fetch origin --prune`
   * `git status --short`
   * `git diff --stat ${input:baseBranch}..HEAD`
   * `git diff --name-only ${input:baseBranch}..HEAD`
   * `git log --oneline --decorate ${input:baseBranch}..HEAD`
* Azure DevOps MCP tools:
  * `mcp_ado_search_workitem` for discovery.
  * `mcp_ado_wit_get_work_item` or `mcp_ado_wit_get_work_items_batch_by_ids` for hydration.
  * `mcp_ado_wit_list_backlogs` and `mcp_ado_wit_list_backlog_work_items` for hierarchy context when required.
* Workspace utilities: `list_dir`, `read_file`, `grep_search` to locate artifacts.
* Avoid disallowed tools (e.g., `mcp_ado_wit_my_work_items`). Persist all tool output into planning files per #file:./ado-wit-planning.instructions.md

````markdown
<!-- <example-git-diff-commands> -->
```bash
git fetch origin --prune
git status --short
git diff --stat ${input:baseBranch}...HEAD
git diff --name-only ${input:baseBranch}...HEAD
git log --oneline --decorate ${input:baseBranch}..HEAD
```
<!-- </example-git-diff-commands> -->
````

## Inputs & Artifact Selection

1. Prioritize artifacts in this order:
   * Explicit `${input:researchDocuments}` paths.
   * `${input:taskPlan}` or `${input:taskDetails}`.
   * Documents or attachments inferred from the conversation.
   * Current branch diff versus `${input:baseBranch}` when no documents or explicit user direction are available.
2. Normalize artifact names per #file:./ado-wit-planning.instructions.md and create/reuse the planning folder (common types: `research`, `plan`, `details`, `changes`).
3. Log each artifact in `planning-log.md` under **Discovered Artifacts & Related Files** with status `Not Started` before analysis.

### Discovery-Only Mode (`${input:discoverUserStoriesOnly}`)

* When this optional input is `true`, run the workflow in discovery-only mode.
* Discovery-only mode requires locating existing User Stories that best match the provided context without creating new work items or modifying existing ones.
* Capture all surfaced User Stories in planning files with action `No Change` and include rationale linking them to the analyzed artifacts.
* Skip drafting new descriptions, acceptance criteria, or field updates; point back to the current state captured from Azure DevOps.
* Ensure the handoff lists each discovered User Story marked as `No Change` and cites supporting artifacts.

## Workflow Overview

### Phase 0 – Prepare Context

1. When no documents or explicit user direction exist, run the git commands above with `${input:baseBranch}` as the comparison branch; record changed files, commit summaries, and diff stats in `planning-log.md`.
2. Treat all changed paths and commits as supplemental artifacts when deriving requirements whenever git context is collected.

### Phase 1 – Analyze Source Material

1. Read each provided or inferred document to completion (`read_file` paging to EOF as needed).
2. Capture key findings, requirements, and open questions in `artifact-analysis.md` and `planning-log.md`.
3. Note cross references between artifacts and store excerpts under the planning templates defined in #file:./ado-wit-planning.instructions.md

### Phase 2 – Build Requirements & Keyword Groups

1. Translate artifact findings and git insights into capability-oriented requirements grouped by persona or system impact.
2. Maintain ACTIVE KEYWORD GROUPS combining nouns and verbs for Azure DevOps search; include component names or file paths when relevant.

````markdown
<!-- <example-keyword-groups> -->
```text
("azureml" OR "workload identity") AND ("acr" OR "dual access")
("terraform" OR "blueprint") AND ("firewall" OR "allow list")
```
<!-- </example-keyword-groups> -->
````

### Phase 3 – Discover Existing Work Items

1. For each keyword group, call `mcp_ado_search_workitem` with:
   * `project`: `[${input:adoProject}]` unless overridden.
   * `searchText`: constructed from ACTIVE KEYWORD GROUPS using OR/AND syntax.
   * `workItemType`: first `["Epic"]` to catalog existing parents for Features. Do not plan to update or create epics within this workflow.
   * `top`: 50 (reduce only if required) and increment `skip` until fewer results return than requested.
   * Optional filters: `areaPath`, `iterationPath`. Always include a `state` filter that covers `New`, `Active`, and `Resolved` unless the user specifies a different state set.
2. Repeat the search for `["Feature"]`, biasing selections toward existing work. Favor alignment to the closest existing Feature even if story scope needs consolidation, and prioritize results in `New`, `Active`, or `Resolved` state.
3. Perform a final pass for `["User Story"]` only after capturing candidate epics and features so duplicate narratives are avoided. Include `New`, `Active`, and `Resolved` stories so related but closed work can be linked or left unchanged.
4. Hydrate results immediately via `mcp_ado_wit_get_work_item` (batch variant allowed) and log outcomes under **Discovered ADO Work Items** in `planning-log.md`.
5. Compute similarity using the matrix from #file:./ado-wit-planning.instructions.md recording scores (e.g., `ADO-1234=0.78`) in both `planning-log.md` and `work-items.md`, capturing the current `System.State` for traceability.
6. Capture titles, states, parents, and acceptance criteria in `artifact-analysis.md` for quick reference, noting epic-to-feature relationships.
7. When `${input:discoverUserStoriesOnly}` is `true`, prioritize the `User Story` searches first, recording relevant parent Features for context but skipping Epic/Feature creation discussions entirely. Continue to limit the search to stories in `New`, `Active`, or `Resolved` state.

### Phase 4 – Decide Parents & Scope

1. Combine user guidance, artifact intent, and similarity scores to anchor every Feature beneath an existing Epic. If no Epic meets a similarity of ≥ 0.60, flag the gap in `planning-log.md` under **Notes** and request clarification instead of proposing a new Epic.
2. Reconcile requirements against existing Features before considering new ones:
   * Similarity ≥ 0.70 (or user-specified) → adopt the existing Feature.
   * Similarity 0.50-0.69 → mark as `Review` with rationale describing alignment adjustments needed.
   * Similarity < 0.50 → only plan a new Feature when the user explicitly approves or the scope cannot be merged into any existing Feature without breaking intent.
3. Document reasoning and selected parents in `planning-log.md`, including Epic references and justification for any new Feature requests.
4. Structure User Story scope to remain broad and persona-focused; consolidate overlapping requirements into the fewest stories that still deliver value under the chosen Feature.
5. Validate every referenced Epic and Feature using `mcp_ado_wit_get_work_item`; record confirmations and note that epics must remain unchanged by this workflow.
6. When `${input:discoverUserStoriesOnly}` is `true`, skip parent selection changes entirely and instead align each discovered User Story with its existing parent hierarchy while documenting why it satisfies the requested work.

### Phase 5 – Draft & Document Work Items

1. Author titles:
   * Features → concise capability statement (e.g., `Enable AzureML registry firewall posture propagation`).
   * User Stories → `As a <persona>, I <need|want|would like> <outcome>` and keep the outcome broad enough to encompass the combined requirements.
2. Build descriptions and requirements; include persona sentence, rationale (`So that...`), and aggregated requirements covering the collected artifacts and branch changes in as few bullets as possible.
3. Populate acceptance criteria with verifiable bullet points. Preserve validated legacy content during updates and ensure criteria remain extensible for adjacent work. When leveraging a `Resolved` User Story, prefer an action of `No Change` and add a `Related` link from any new or updated story back to the resolved item.

````markdown
<!-- <template-user-story-description> -->
```markdown
As a {{persona}}, I {{need|want|would like}} {{capability}}.

So that {{outcome or business value}}.

## Requirements
* {{Requirement derived from artifact or diff}}
* {{Requirement covering dependency or non-functional behavior}}

## Notes
* {{Optional implementation constraints or references}}
```
<!-- </template-user-story-description> -->
````

````markdown
<!-- <example-acceptance-criteria> -->
```markdown
* Blueprint plan shows new variables with defaults documented.
* Deploying with allow list populated restricts registry access to provided CIDRs.
* AzureML workspace output references posture metadata without breaking existing consumers.
```
<!-- </example-acceptance-criteria> -->
````

4. Update planning files after each major step:
   * `artifact-analysis.md` → working titles, descriptions, acceptance criteria, suggested field values, related artifacts.
   * `work-items.md` → action (Create/Update), similarity scores, field deltas, relationship mapping, git diff highlights.
   * `planning-log.md` → status updates, discovery notes, pending investigations.
5. When `${input:discoverUserStoriesOnly}` is `true`, set the action to `No Change`, record the discovered User Story details verbatim, and capture supporting context explaining why the existing item remains sufficient.

### Phase 6 – Assemble Handoff & Validate

1. Build `handoff.md` with Create entries first, followed by Updates; include checkboxes, summaries, relationships, and supporting artifacts.
2. Ensure planning file paths appear in the **Planning Files** section for quick navigation.
3. Verify consistency across planning files and `handoff.md` (aligned WI references, totals, and decisions).
4. Confirm every User Story references an existing Feature or a user-approved new Feature; log unresolved questions under **Notes** in `planning-log.md`.
5. Deliver the final conversational recap covering counts, parents, unresolved reviews, and the planning workspace location.
6. When `${input:discoverUserStoriesOnly}` is `true`, list each surfaced User Story under **Work Items** with a `(No Change)` action and summarize why it remains the best fit for the requested work.

````markdown
<!-- <example-handoff-entry> -->
```markdown
* [ ] (Create) WI003 User Story
   * Parent: Existing Feature WI872 (Reusable ACR dual access posture)
   * Summary: Document AzureML posture defaults within the shared dual-access pattern.
  * Supports: .copilot-tracking/research/20250928-acr-dual-access-blueprint-extension-research.md
```
<!-- </example-handoff-entry> -->
````

## Compliance Checklist

<!-- <important-compliance-checklist> -->
- [ ] When documents or explicit user direction are absent, git context captured and logged before discovery
- [ ] All referenced artifacts fully read and summarized in planning files
- [ ] ACTIVE KEYWORD GROUPS documented and reused for work item search
- [ ] Epics and Features discovered (in that order) with hydration for every candidate before inspecting User Stories
- [ ] Similarity scores recorded with rationale in planning files
- [ ] Persona titles, consolidated requirements, and acceptance criteria present for each User Story
- [ ] `work-items.md`, `artifact-analysis.md`, `planning-log.md`, and `handoff.md` are synchronized
- [ ] Create entries precede Update entries in `handoff.md`, with supporting artifact references
- [ ] No new Epics proposed; existing Features preferred with justification for any new Feature requests
- [ ] Final response includes counts, parent selections, outstanding reviews, and planning folder path
<!-- </important-compliance-checklist> -->

## Success Criteria

* Planning files capture traceability from artifacts and git diffs to proposed work items.
* `handoff.md` references supporting documents and orders actions correctly for #file:../prompts/ado-update-wit-items.prompt.md
* Parent-child relationships, titles, requirements, and acceptance criteria follow mandated formats.
* Documented decisions reflect user guidance, and only necessary Features are proposed.
