---
mode: "agent"
description: "Retrieve ALL @Me work items (prioritized types first, then fallback) using mcp_ado_search_workitem with paging; progressively persist raw + hydrated JSON and output summary table."
---

# Get My Work Items (Full Retrieval, Progressive Raw Export)

You WILL retrieve all work items assigned to the current user (`@Me`) within the specified Azure DevOps project using ONLY the provided Azure DevOps tools. High-level flow: search (with optional fallback) -> progressive raw persistence -> per-item hydration (individual `mcp_ado_wit_get_work_item` calls) -> final summary/table. Detailed steps are defined in Phases and Outputs sections.

NO local re-ordering beyond natural server return order. NO reliance on saved queries. DO NOT use `wit_my_work_items` anywhere.

## Inputs

- ${input:project:edge-ai}: Azure DevOps project name or ID (REQUIRED)
- ${input:types:Bug, Task}: Comma-separated prioritized Work Item Types to fetch first (case-insensitive). Default: Bug, Task.
- ${input:fallbackTypes:User Story}: Comma-separated secondary Work Item Types to fetch ONLY IF the first pass returns zero results. Default: User Story.
- ${input:states:Active, New}: (Optional) Comma-separated workflow states to include. If empty, include all states. Default restricts to Active, New.
- ${input:areaPath}: (Optional) Area Path filter. If supplied, include only work items under this Area Path (exact or descendant as supported by search behavior).
- ${input:iterationPath}: (Optional) IterationPath filter. When provided, you MUST append ` IterationPath:"${input:iterationPath}"`to the`searchText` (note the leading space) so that server-side search scopes results to that iteration. Do NOT add if empty.
- ${input:fields}: (Optional) Explicit additional fields to hydrate (beyond defaults) when calling `mcp_ado_wit_get_work_item` for each work item.
- ${input:pageSize:200}: Page size for each `mcp_ado_search_workitem` call (attempt to use 200; adjust down only if API enforces a lower maximum).

## Outputs

You MUST produce and/or update the following artifacts (referenced in Detailed Required Behavior):

1. Progressive Raw JSON Artifact (Search Phase): `.copilot-tracking/workitems/{YYYYMMDD}-assigned-to-me.raw.json` containing minimal fields for each discovered work item plus search metadata. (See Outputs JSON Structure.)
2. Hydrated JSON (Same File, Updated): Same path; enriched fields merged batch-wise; includes `hydration` status section and completion flags.
3. Conversation Summary Table: Markdown table (ID | Type | Title | Tags | Priority | Stack Rank) with `<br />` inserted for Title wrapping (~70 char boundaries) and between tag tokens.
4. Completion Summary: Count of hydrated work items, JSON file path, whether fallback types were used, and the table (or explicit statement that none were found).

### Outputs JSON Structure

Always keep this output structure top of mind:

<!-- <output-json-structure> -->
```json
{
  "project": "${input:project}",
  "timestamp": "<ISO8601>",
  "usedFallback": false,
  "search": {
    "types": ["Bug", "Task"],
    "fallbackTypes": ["User Story"],
    "states": ["Active", "New"],
    "areaPath": null,
    "iterationPath": null,
    "pageSize": 200,
  },
  "idsOrdered": [123, 124], // all ids returned from mcp_ado_search_workitem calls
  "hydration": {
    "remainingIds": [124],  // initially set to all ids after mcp_ado_search_workitem calls
  },
  "items": [
    {
      "id": 123,
      "fields": {
        /* any additional matching returned fields and ${input:fields} after mcp_ado_wit_get_work_item calls */
        "System.Id": 123,
        "System.WorkItemType": "Bug",
        "System.Title": "...",
        "System.State": "Active",
        "System.Tags": "...",
        "System.CreatedDate": "...",
        "System.ChangedDate": "...",
        "System.Reason": "...",
        "System.Parent": "...",
        "System.AreaPath": "...",
        "System.IterationPath": "...",
        "System.TeamProject": "...",
        "System.Tags": "...",
        "System.Description": "...",
        "Microsoft.VSTS.Common.AcceptanceCriteria": "...",
        "Microsoft.VSTS.TCM.ReproSteps": "...",
        "Microsoft.VSTS.Common.Priority": "...",
        "Microsoft.VSTS.Common.StackRank": "...",
        "Microsoft.VSTS.Common.ValueArea": "...",
        "Microsoft.VSTS.Common.BusinessValue": "...",
        "Microsoft.VSTS.Common.Risk": "...",
        "Microsoft.VSTS.Common.TimeCriticality": "...",
        "Microsoft.VSTS.Scheduling.StoryPoints": "...",
        "Microsoft.VSTS.Scheduling.OriginalEstimate": "...",
        "Microsoft.VSTS.Scheduling.RemainingWork": "...",
        "Microsoft.VSTS.Scheduling.CompletedWork": "...",
        "System.AssignedTo": "...",
        "System.CreatedBy": "...",
        "System.CreatedDate": "...",
        "System.ChangedBy": "...",
        "System.ChangedDate": "...",
        "System.CommentCount": "...",
        "Microsoft.VSTS.Common.Severity": "...",
        "System.BoardColumn": "...",
        "System.BoardColumnDone": "...",
        "System.BoardLane": "..."
      }
    }
  ]
}
```
<!-- <output-json-structure> -->

## Phases (Overview)

Update the task list with the following:

0. List Dir Existing Workitems (update or create raw file)
1. Build Search Criteria (construct filters & searchText)
2. First Search Pass (paging when needed)
3. Optional Fallback Search Pass (only if first search produced zero items)
4. Persist Raw JSON (See Outputs JSON Structure)
5. Required Re-state All Item Fields (See Outputs JSON Structure)
6. Hydration Get Work Item (See Outputs JSON Structure)
7. Final Output Table (See Outputs)

## Detailed Required Behavior

### 0. List Dir Existing Workitems

You must first `list_dir` on `.copilot-tracking/workitems` and identify if there is already an existing `.copilot-tracking/workitems/{YYYYMMDD}-assigned-to-me.raw.json` file that you will be updating (if exists) or creating (if not existing).

### 1. Build Search Criteria

Parse `${input:types}` and `${input:fallbackTypes}` into two ordered, case-insensitive sets (trim whitespace). Parse `${input:states}` similarly (unless blank). Build `searchText` ALWAYS including `a:@Me`. If `${input:iterationPath}` present, append ` IterationPath:"${input:iterationPath}"` exactly (space-prefixed) to `searchText`. (If state filters provided, use `state` parameter; do NOT redundantly embed state text inside `searchText`).

### 2. First Search Pass (Prioritized Types)

Call `mcp_ado_search_workitem` repeatedly with:

- `project`: array containing `${input:project}`
- `searchText`: must include `a:@Me`
- `workItemType`: array of prioritized types (parsed from `${input:types}`) OR omit if empty after parsing
- `state`: array of states if provided
- `areaPath`: pass only if `${input:areaPath}` provided
- `top`: `${input:pageSize}`
- `skip`: advance by `${input:pageSize}` until a page returns fewer than `${input:pageSize}` or zero

After each page (See Outputs JSON Structure):

- Add `System.Id`'s to `idsOrdered` list if missing.
  - Only when `System.Id` is added to `idsOrdered` then you must add it to `hydration.remainingIds`.

### 3. Optional Fallback Search Pass

If, after exhausting paging for prioritized types, zero items were collected, perform the same paging logic using fallback types list (`${input:fallbackTypes}`). Reinitialize paging counters but reuse the SAME output file (overwrite structure with empty items first if not yet written). Mark a boolean `"usedFallback": true` in the JSON (include this key only if fallback was used).

### 4. Persist Raw JSON (See Outputs JSON Structure)

File path: `.copilot-tracking/workitems/{YYYYMMDD}-assigned-to-me.raw.json` (UTC date), refer to Outputs JSON Structure section for detailed JSON structure to output and update. Ensure folder exists.

Update after each page: refresh `timestamp`, append to `items`, recalc `idsOrdered` (ordered by initial encounter). Keep `search.completed = false` until hydration finishes.

### 5. Required Re-state All Item Fields (See Outputs JSON Structure)

You are now required to review the Outputs JSON Structure and re-state exactly the items fields (as a markdown list) that you will be persisting when hydrating each item.
The user must see exactly what you are looking for and what you will be persisting.
When persisting you must verify that you've included all fields from this list
**Warning**, if you skip this step then you may not persist all of the required data.

### 6. Hydration Get Work Item (See Outputs JSON Structure)

After all search pages (and fallback if used) complete AND there is at least one item in `hydration.remainingIds`:

- Iterate `hydration.remainingIds` in order. For each remainingId, call `mcp_ado_wit_get_work_item`.
- After 3-5 `mcp_ado_wit_get_work_item` calls, merge (hydrate) returned field values into the corresponding `items[i].fields` (overwrite any previously stored fields).
- After EACH successful item hydration, remove that id from `hydration.remainingIds`.
- Important, if a `mcp_ado_wit_get_work_item` call fails, surface the error and stop (leave remaining ids intact for potential retry in a subsequent run).

#### 6.a Hydration Field Persistence Rule (Critical)

ALL fields returned by `mcp_ado_wit_get_work_item` that are part of the requested hydration field list (See Outputs JSON Structure) MUST be written immediately into the single JSON artifact `.copilot-tracking/workitems/{YYYYMMDD}-assigned-to-me.raw.json` during that same hydration cycle.

Mandatory rules:
- No temporary, staging, or intermediate files may be created; the ONLY persistence target is the dated `*.raw.json` file.
- If the server omits a requested field, do not fabricate it; absence is acceptable. If it returns the field with `null` or empty value, persist as-is.
- Never remove previously stored fields when adding new ones; merges are additive/overwriting per field key.
- User-provided `${input:fields}` are treated identically to defaults: if returned, they MUST appear under the item's `fields` object after that hydration step.
- The on-disk JSON after each hydration call must reflect the latest known complete set of fields for every hydrated item so far (idempotent on re-runs).

### 7. Final Output Table (See Outputs)

After hydration completes (or if zero items found), output to the conversation:

- A markdown table with columns: ID | Type | Title | Tags | Priority | Stack Rank
- For Title: Replace long text by inserting `<br />` every ~70 characters at natural space boundaries (best-effort) to wrap.
- For Tags: If empty or null, leave cell blank. Otherwise split semicolon- or comma-delimited tag strings (trim whitespace) into separate lines joined by `<br />`.
- If Priority or Stack Rank missing, display `-`.

### Error Handling

- If any tool call fails, surface the raw error content and stop further processing (persist whatever progress possible before stopping).

## Edge Cases & Rules

- If both prioritized and fallback passes are empty, do not perform hydration phase.
- NEVER invoke `wit_my_work_items`, `wit_get_query`, or `wit_get_query_results_by_id` in this prompt.

## Completion Summary Requirements (See Outputs: Completion Summary)

When done, provide:

- Count of work items hydrated
- Path to JSON file
- Whether fallback types were used
- The markdown table described above (or a statement that none were found)

## Compliance Checklist (Self-Evaluate Before Responding)

<!-- <important-compliance-checklist> -->
- [ ] No disallowed tools used (`wit_my_work_items`, query tools)
- [ ] Paging implemented for full retrieval
- [ ] Progressive persistence of raw json artifact file
- [ ] Hydration merged additional fields in-place in raw json artifact file
- [ ] IDs/order preserved; no reordering
- [ ] Fallback executed only if prioritized search yielded zero items
- [ ] Output table uses `<br />` for Title wrapping & Tag splitting
- [ ] Empty / null tags → blank cell
- [ ] IterationPath appended to searchText only if provided
- [ ] Single JSON artifact file updated throughout
- [ ] All requested hydration fields persisted for each item
- [ ] No temporary files created
- [ ] No requested field suppressed/filtered/deferred
- [ ] Read-in and reviewed the final JSON artifact file before any response to the user
<!-- </important-compliance-checklist> -->

---

Proceed getting my work items by following all phases in order
