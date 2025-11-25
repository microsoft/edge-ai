---
mode: "agent"
description: "Generate a single comprehensive work item handoff markdown from latest raw assigned-to-me work items with repo context enrichment."
---

# Work Item Handoff (Repo-Enriched, Resumable, Markdown-Only)

You WILL read the latest raw JSON produced by `get-my-work-items` and generate ONE (1) comprehensive handoff markdown file (`*.handoff.md`). You WILL enrich items using repository context. Provide a deep, implementation-ready handoff section for the top recommendation, followed by structured handoff sections for every remaining work item (respecting optional max item cap). File must be idempotent & resumable.
Represent structured data using well-formed markdown tables, bullet lists, and labeled inline segments for clarity and consistency.

## Inputs

- ${input:rawPath}: Optional explicit path to raw JSON; else discover latest `.copilot-tracking/workitems/*-assigned-to-me.raw.json` (use `list_dir`).
- ${input:handoffPath}: Optional explicit output path (must end with `.handoff.md`). If omitted, derive `.copilot-tracking/workitems/YYYYMMDD-assigned-to-me.handoff.md` (date from raw file name or current UTC date if ambiguous).
- ${input:maxItems:all}: Optional numeric cap; default all.
- ${input:boostTags}: Optional comma/semicolon separated tags that, if present in an item, may elevate it to top recommendation.
- ${input:forceTopId}: Optional specific ID to force as top recommendation (overrides boost logic if found).

## Azure DevOps Comment Retrieval

<!-- <ado-comment-tools> -->

Use `mcp_ado_wit_list_work_item_comments` to fetch comments when missing from the *.raw.json file. If none, omit "Comments Relevant".

Keep only materially useful units: problems, decisions, deployments, errors/stack traces (use fenced `text` block for multi-line), metrics, blockers. Skip social/duplicate or bot noise unless it adds unique technical data. Preserve exact error strings & file/config names.

Format each unit as a bullet starting with `Author - YYYY-MM-DD:`. Split multiple units from one comment into separate bullets. Order by timestamp ascending. Omit section if no retained units.

<!-- </ado-comment-tools> -->

## Outputs

### Handoff Content Requirements Per Item

Each work item section MUST surface enough context to transition directly into detailed technical research & planning.

Include (when present):

- Metadata: Id, WorkItemType, Title, State, Priority, StackRank, Parent, Tags (split semicolon/comma), AssignedTo, ChangedDate.
- Narrative Summary: 2-5 sentence synthesized intent & desired outcome.
- Description & Acceptance Criteria (verbatim or distilled if very long-retain critical bullet points).
- Blockers / Risks: extraction from State/Reason/comments.
- Comments Relevant: concise actionable excerpts with author + date `(Author - YYYY-MM-DD): excerpt`.
- Stack Traces: fenced code block(s) when present.
- Errors / Issues: bulleted list of distinct error messages or problem statements.
- Repository Context:
  - Top Files (≤10): `path` + short rationale.
  - Other Related Files Summary: bullet lines for broader areas or patterns.
  - Implementation Detail Leads: hypotheses, key functions/classes, integration points.
  - Data / Config Touchpoints: env vars, config files, infra modules.
  - Related Items: IDs with brief relation rationale (parent/child/sibling/feature).
- Ready-to-Research Prompt Seed: concise markdown list (no code fence) capturing Objective, Unknowns, Candidate Files, Risks, Next Steps.

Ordering: The top recommendation section appears first with deeper elaboration (may expand Implementation Detail Leads & Unknowns). Remaining items get a consistent but slightly more concise format.

### Required Handoff Markdown File

Do not duplicate full per-item details here.

<!-- <handoff-structure> -->

Top-level title:
Assigned to Me - Handoff (YYYY-MM-DD)

Sections (order MUST match):

1. Top Work Item Recommendation Handoff
2. Additional Work Item Handoffs
3. Progress
4. Next Step - Task Researcher Handoff

#### Top Work Item Recommendation Handoff

Heading format: `## Top Recommendation - WI {id} ({WorkItemType})`
Subsections (suggested): Summary, Metadata Table, Description & Acceptance Criteria, Blockers / Risks, Comments Relevant, (optional) Stack Traces, (optional) Errors / Issues, Repository Context (Top Files, Other Related Files Summary, Implementation Detail Leads, Data / Config Touchpoints, Related Items), Ready-to-Research Prompt Seed (markdown bullet / label list: Objective, Unknowns, Candidate Files, Risks, Next Steps).

#### Additional Work Item Handoffs

Heading: `## WI {id} - {Title}` (truncate Title >80 chars with ellipsis). Condensed subsections: Summary, Metadata, Key Files (≤5), Blockers/Risks (if any), Implementation Detail Leads, Ready-to-Research Seed (bullet / label list: Objective, Unknowns, Candidate Files, Next Steps).

#### Progress

Counts: `Summarized: X / Total: Y` plus summarized ID list and remaining ID list.

#### Next Step - Task Researcher Handoff

Guidance: choose the Top Recommendation or any other Ready-to-Research Prompt Seed to begin next-phase research. Provide a consolidated Handoff Payload bullet list (no fenced code):

- Top Recommendation ID: <id>
- All Summarized IDs: <comma-separated list>
- Date: YYYY-MM-DD

<!-- </handoff-structure> -->

#### Handoff File Naming Rules

- Must end with `.handoff.md`.
- Must reside in the SAME directory as the raw JSON file.
- Date fragment (YYYYMMDD) MUST align with raw filename date if present; else use current UTC date.

## Summarization Protocol

Update the task list with the following:

1. Discover / load raw JSON (validate structure: must contain `items`).
2. Determine handoff path (input override or derived path).
3. If file exists: parse existing headings to collect already summarized IDs.
4. Determine top recommendation (precedence: `forceTopId` if valid -> boosted tag density -> first remaining).
5. Do light research searching and reading existing files in codebase for top recommendation.
6. Update the top recommendation and generate / append sections in required order.
7. Add a summary section for the top recommendation that includes hand-off material that is everything needed to do deep task research.
8. Write final path to conversation with counts (summarized vs total vs remaining).
9. Do NOT create ANY `.summary.json` or other JSON artifacts.

Important: If the user wants to use a different work item for a top recommendation then you must:

  1. Remove the top recommendation.
  2. Add the user's top recommendation.
  3. Do light research for the new top recommendation from the user.
  4. Add all information for the new top recommendation including hand-off material.

Important: If the *.handoff.md document already exists then you must first read it in and continue with the existing document.

### Resumable Behavior

- If the handoff file already exists, parse existing section headers to determine already summarized IDs (pattern: `## WI {id} -`).
- Append only missing items while preserving prior content verbatim.
- Never duplicate a work item section. Maintain original order for existing sections; new sections follow in correct relative order of raw JSON.

## Handoff Examples

<!-- <example-top-recommendation-section> -->

````markdown
## Top Recommendation - WI 1234 (Bug)

### Summary

User sessions intermittently expire due to race in token refresh pipeline causing 401 cascades.

### Metadata

| Field     | Value            |
|-----------|------------------|
| State     | Active           |
| Priority  | 1                |
| StackRank | 12345            |
| Parent    | 1200 (Feature)   |
| Tags      | auth;performance |

### Description & Acceptance Criteria

<verbatim or distilled content>

### Blockers / Risks

- Potential data loss if refresh fails mid-transaction.

### Comments Relevant

John Doe - 2025-08-20: Observed spike in 401s after deployment.

### Stack Traces

```text
TraceLine1
TraceLine2
```

### Errors / Issues

- 401 Unauthorized after token refresh

### Repository Context

**Top Files**

1. src/auth/refresh.ts - Implements refresh logic suspected in race.
2. src/middleware/session.ts - Consumes refreshed token.

**Other Related Files Summary**

- src/config/\* - Token TTL settings.

**Implementation Detail Leads**

- Add mutex around refresh sequence.

**Data / Config Touchpoints**

- ENV TOKEN_REFRESH_SKEW_MS

**Related Items**

- WI 1250 (Task) - Add integration tests.

### Summary

**Objective:** Eliminate race in token refresh to stop session invalidation spikes.
**Unknowns:** Exact concurrency trigger; Impact on downstream cache
**Candidate Files:** src/auth/refresh.ts; src/middleware/session.ts
**Risks:** Session expiry cascade
**Next Steps:** Instrument refresh path; Add lock or idempotent guard
````

<!-- </example-top-recommendation-section> -->

<!-- <example-additional-item-section> -->

```markdown
## WI 1300 - Refactor logging adapter for async streams

**Summary:** Logging adapter drops messages under high concurrency; refactor for backpressure.
**Metadata:** State=Active | Priority=2 | StackRank=14000 | Type=Task | Parent=1200
**Key Files:** src/logging/adapter.ts (drops messages), src/logging/queue.ts (enqueue latency)
**Blockers/Risks:** Potential data loss; noisy retries.
**Implementation Detail Leads:** Consider bounded channel; ensure flush on shutdown.
**Ready-to-Research Prompt Seed:**
Objective: Ensure lossless async logging
Unknowns: Optimal buffer size
Candidate Files: src/logging/adapter.ts
Next Steps: Benchmark current drop rate
```

<!-- </example-additional-item-section> -->

## Compliance Checklist

<!-- <important-compliance-checklist-summarize-handoff> -->

- [ ] Located latest raw JSON (or used provided rawPath)
- [ ] Derived handoff path with .handoff.md extension in same directory
- [ ] Resumed without duplicating existing WI sections
- [ ] Selected top recommendation via forceTopId / boostTags / fallback order
- [ ] Generated Top Recommendation section with all required subsections
- [ ] Generated sections for ALL remaining (within maxItems) work items
- [ ] Included Progress section with summarized & remaining IDs
- [ ] Included Next Step section with minimal bullet-list Handoff Payload
- [ ] All structured data rendered as well-formed markdown (tables, bullets, labeled lists)
- [ ] Did NOT create ANY .summary.json or other JSON artifacts
- [ ] Limited Top Files to ≤10, Additional Items Key Files to ≤5
- [ ] Omitted empty sections (e.g., Stack Traces) when data absent
- [ ] Truncated long headings (>80 chars)

<!-- </important-compliance-checklist-summarize-handoff> -->

---

Proceed following the summarization protocol
