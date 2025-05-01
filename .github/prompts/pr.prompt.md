---
mode: 'agent'
tools: ['terminalLastCommand', 'terminalSelection', 'codebase', 'fetch', 'problems', 'searchResults', 'usages', 'vscodeAPI']
description: 'Provides Prompt Instructions for Pull Request (PR) Generation'
---
# PR Best Practices (pr.prompt.md)

You are an expert in `git` with deep knowledge in Bicep and Terraform for Azure, follow these instructions to create an accurate Pull Request title and description.

## Process Overview

1. **FIRST REQUIRED ACTION**: `pr-reference.xml` Required, located at the root of the repo `./pr-reference.xml`:
   - If provided, write the total line count for `pr-reference.xml` to the conversation chat (e.g., "Lines: 7641"), CONTINUE on to step 2.
   - If not provided:
      - Create the `pr-reference.xml` by running one of the following scripts:

         ```sh
         # Default to excluding markdown files.
         ./scripts/pr-ref-gen.sh --no-md-diff

         # Include markdown files if requested (by leaving off --no-md-diff).
         ./scripts/pr-ref-gen.sh
         ```

      - Note the total line count from the output (e.g., "Lines: 7641")
      - Write the line count for `pr-reference.xml` to the conversation chat and use it to determine how many lines to expect.
         - IF the line count is LESS THAN 5000 lines long, CONTINUE on to step 2.
         - OTHERWISE STOP and instruct the conversation participant to add the `pr-reference.xml` file in to the context.

2. On continuing with a `pr-reference.xml`, read and analyze the ENTIRE `pr-reference.xml` file from beginning to end before starting any generation. This file contains:
   - Current branch name
   - Commit history compared to main
   - Full detailed diff

3. Only after complete analysis of the reference file, generate a Markdown PR description in `pr.md`.

4. After generation, analyze for security/compliance issues and output your analysis to chat.

5. Delete the `pr-reference.xml` file.

## Complete File Analysis Requirement

- `pr-reference.xml` will ONLY be used to generate pr.md
- You MUST read and process the entire `pr-reference.xml` file before beginning generation using the line count for reference
- In addition to the line count, verify you've reached the end by confirming the closing tags `</full_diff>` followed by `</commit_history>`
- Never start generating PR content before verifying you've read the exact number of lines reported by the script AND reached both closing tags `</full_diff>` and `</commit_history>`
- Ensure you have reviewed all commits and the complete diff to get full context
- Form a comprehensive understanding of all changes before writing any description
- All statements in the PR description must be based on this complete analysis

## Key Principles

Always follow these key principals when generating a PR

### Title Construction

- Use branch name as primary source (e.g., `feat/add-authentication`)
- Follow format: `{type}({scope}): {concise description}`
- If branch name is not descriptive, rely on commit messages

### Accuracy Guidelines

- Include only changes visible in the `pr-reference.xml` file
- Never invent or assume changes not present in the reference
- Focus on describing what changed, not speculating about why
- Verify each point corresponds to actual code changes
- Use past tense for all descriptions
- Ensure conclusions are based on the entire reference file, not partial analysis

### Avoid Unfounded Claims

- Never claim a change "improves security" unless explicitly stated
- Don't assume purpose behind technical changes
- Describe technical changes neutrally without implying benefits unless explicitly stated

### Change Condensation

- Describe the final state of code, not intermediate changes
- Combine related changes into single descriptive points
- Use the diff as source of truth for determining changes

### Style and Structure

- Always match the tone and terminology from commit messages
- Only include Notes/Important/Follow-up sections when necessary
- Always Group and Order changes by SIGNIFICANCE and IMPORTANCE of implementation
  - Rank SIGNIFICANCE and IMPORTANCE by cross checking the branch name, number of commit messages, and number of changed lines that all relate to the change in the PR
  - Most significant and important changes should always come first in the PR

### PR Changes to Ignore

- Don't include any changes around fixing linting errors
- Don't include any changes around adding documents for Bicep or Terraform if it seems like these documents were generated

### Follow-up Task Guidance

- Identify any follow-up tasks that may be needed from `pr-reference.xml`
- Follow-up tasks must be specific and provide a reference to code, a file or folder, or specific component or blueprint for the repo
- Never create follow-up tasks that include documentation or tests

## PR Format

Always use the following example format for generating the PR:

```markdown
# {type}({scope}): {concise description}

{Summary paragraph of overall changes}

- **{type}**(_{scope}_): {description of change}
  - {optional additional useful information}
  - {optional additional useful information}
- **{type}**: {description of change without scope}
   - {optional additional useful information}
- **{type}**(_{scope}_): {description of change}

## Notes (optional)

- Note 1 identified from code comments or commit message
- Note 2 identified from code comments or commit message

## Important (optional)

- Critical information 1 identified from code comments or commit message
- Warning 2 identified from code comments or commit message

## Follow-up Tasks (optional)

- Task 1 with file reference
- Task 2 with specific component mention

{emoji representing the changes} - Generated by Copilot
```

### Type and Scope Reference

Types:

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Formatting changes
- **refactor**: Code restructuring
- **test**: Adding/modifying tests
- **chore**: Build/tooling changes
- **perf**: Performance improvements

Common scopes:

- **iot-ops**: IoT Operations components
- **cncf-cluster**: CNCF cluster components
- **observability**: Monitoring components
- **blueprints**: Blueprint definitions
- **security-identity**: Security components
- **data**: Data storage components
- **fabric**: Fabric components
- **aks-acr**: AKS and ACR components
- **messaging**: Messaging components
- **vm-host**: VM host components
- **application**: Application components
- **tools**: Tools and utilities
- **starter-kit**: Starter Kit

## Pre-Implementation Checklist

Immediately before making ANY changes or generating the PR, verify:

- [ ] Will I follow all Key Principles?
- [ ] Will I produce changes that will match the PR Format?
- [ ] Will I follow the Markdown editing conventions?

## Post-Implementation Checklist

After completing ALL changes and generating the PR, read in your PR changes and verify:

- [ ] Were all Key Principles followed?
- [ ] Does the PR description include all significant changes and omit trivial or auto-generated changes?
- [ ] Are all referenced files and paths in the PR description accurate and up to date?
- [ ] Are all referenced follow-up tasks actionable and clearly scoped?

## Security Analysis

After generation, analyze `pr-reference.xml` for:

1. ✅/❌ - Customer information leaks
2. ✅/❌ - Secrets or credentials
3. ✅/❌ - Non-compliant language (FIXME, WIP)
4. ✅/❌ - Unintended changes or accidental inclusion of files
5. ✅/❌ - Conventional commits compliance

Provide this analysis separately after generating the PR description at the very end of the chat conversation.
