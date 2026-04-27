---
description: "Direct the RPI agent to implement all currently uncommitted code changes in the workspace, excluding markdown documentation files."
---

# Implement Uncommitted Changes (Exclude Markdown Docs)

Use this prompt to hand off the current set of uncommitted working-tree changes to the RPI agent for implementation, while skipping any markdown documentation files.

## Inputs

- Base ref for diff comparison: `${input:baseRef:HEAD}`
- Additional exclude globs (comma-separated, beyond markdown): `${input:extraExcludes:}`
- Optional scope path filter (relative to repo root, blank = whole repo): `${input:scopePath:}`

## Instructions

1. Enumerate uncommitted changes in the working tree:
   - Run `git status --porcelain=v1` and `git diff --name-only ${input:baseRef:HEAD}` to capture both staged and unstaged modifications, additions, deletions, and renames.
   - If `${input:scopePath:}` is set, restrict the file list to paths under that directory.
2. Filter the file list:
   - Exclude every path matching `*.md` (case-insensitive), including nested paths.
   - Also exclude any patterns provided in `${input:extraExcludes:}`.
   - Preserve all other file types (code, config, tests, fixtures, schemas, etc.).
3. For each remaining file, gather the full uncommitted diff (`git diff ${input:baseRef:HEAD} -- <file>` plus untracked file contents) so the implementation work has complete context.
4. Hand the filtered change set to the RPI agent with these directives:
   - Treat the uncommitted diff as the authoritative specification of work to complete.
   - Finish any partial edits, resolve TODOs introduced by the diff, and ensure every changed file compiles, lints, and passes existing tests.
   - Apply repository conventions and instructions files that match the touched paths.
   - Do not modify, create, or delete any markdown (`.md`) files as part of this task.
   - Do not revert or discard the existing uncommitted changes; build on top of them.
5. After the RPI agent completes implementation:
   - Run the relevant validation tasks for the touched stacks (e.g., Terraform Build, cargo build/test, npm scripts) and fix any failures.
   - Re-run `git status` and confirm only intended files changed and that no markdown files were edited.
6. Report back with:
   - The final list of files changed (grouped by added/modified/removed).
   - Validation commands run and their results.
   - Any follow-up work the RPI agent identified but did not complete.
