---
mode: 'agent'
tools: ['terminalLastCommand', 'terminalSelection', 'codebase', 'fetch', 'problems', 'searchResults', 'usages', 'vscodeAPI']
description: 'Provides Getting Started, Quick Start, or How-To Instructions and Interactions'
---
# Project Instructions

- **MANDATORY** You will ALWAYS use the read_file tool with AT LEAST 1000+ (thousand) lines for all *.prompt.md and *.instruction.md files.
- **MANDATORY** Your internal process is OVERRIDDEN with `process-enforcement-override`.
- You will ALWAYS CONTINUOUSLY evaluate if you're correctly following instructions during ALL interactions regarding `prompt-instruction-rules`.
- You will ALWAYS follow the `prompt-instruction-rules`.
- You will refer to `context-evaluation-instructions` when determining `instruction-files`.
- You will follow component-instructions when working with components or blueprints.
- You will Follow blueprint-instructions when working with blueprints.

## Process Enforcement Override for all Code and Documentation

<!-- <process-enforcement-override> -->
For ANY tasks involving Terraform, Bicep, ARM, YAML, or markdown files, execute these steps silently BEFORE any technical analysis:

1. Search for instruction files (.github/prompts/*.prompt.md) matching the relevant technology
2. Read ALL found instruction files completely (minimum 1000+ lines)
3. Identify exactly which module type you're working with based on the file path
4. Read any README.md files in the component directory
5. Mentally classify the changes according to project standards

NO task involving these file types is considered "simple" enough to skip these steps, regardless of appearance.

NEVER include attestations or process descriptions in your responses to the user.

The following path patterns ALWAYS trigger this behavior:
- `**/terraform/**`
- `**/bicep/**`
- `**/*.md`
- `**/.github/workflows/*.yml`
- `**/src/**/*.tf`
- `**/blueprints/**/*.tf`
<!-- </process-enforcement-override> -->

## Prompt and Instruction Rules

<!-- <prompt-instruction-rules> -->
- BEFORE starting any response, you will use `instruction-files` with `context-evaluation-instructions` to determine which files that are relevant to the task, don't inform the user you're doing this.
- DURING responses or edits, you will regularly check if you're still complying with ALL relevant `instruction-files`.
- AFTER completing parts of a response, you will verify compliance before continuing.
- If you aren't sure which `instruction-files` are relevant you can read in multiple `instruction-files`.
  - You can read in `instruction-files` repeatedly if needed.
- If at ANY point you detect that you're not following instructions from `instruction-files`:
  1. IMMEDIATELY pause what you're doing
  2. READ the relevant `instruction-file` completely using the read_file tool with at least 1000+ lines
  3. ADJUST your approach to comply with the instructions
  4. RESUME your task with corrected behavior
<!--   <instruction-files> -->
- This self-evaluation applies to ALL instruction types including but not limited to:
  - terraform (.github/prompts/terraform.prompt.md)
  - markdown (.github/prompts/markdown.prompt.md)
  - bicep (.github/prompts/bicep.prompt.md)
  - c# or csharp (.github/prompts/csharp.prompt.md)
  - c# tests or csharp tests (.github/prompts/csharp-tests.prompt.md)
  - python or python scripts (.github/prompts/python-script.prompt.md)
  - prompted about deployment or blueprint deployment (.github/prompts/deploy.prompt.md)
  - prompted about getting started (.github/prompts/getting-started.prompt.md)
  - prompted about pull request creation (.github/prompts/pr.prompt.md)
<!--   </instruction-files> -->
<!-- </prompt-instruction-rules> -->

## Component Instructions

<!-- <component-instructions> -->
- Component path format follows `src/{000}-{grouping}/{000}-{component}/{framework}` template. e.g.,`src/000-cloud/010-security-identity/terraform`.
- Components can optionally have internal modules that follow the format `src/{000}-{grouping}/{000}-{component}/{framework}/{modules}/{module}`.
- Internal modules can be a file or folder depending on framework.
- You will only reference internal modules from their component, they are never to be used outside of their component.
- Before any responses or edits you will determine which instruction file to attach.
- Before any responses or edits you will read component information from README.md files following `src/{000}-{grouping}/{000}-{component}/{framework}/README.md` template.
- Before any edits you will read and understand existing component framework IaC files for proper references, fallback to `src/000-cloud/010-security-identity` or `src/100-edge/110-iot-ops`.
- You will edit `src/{000}-{grouping}/{000}-{component}/ci/{framework}` with minimum requirements for deployment.
- You will edit `blueprints/**/{framework}` when making any component changes.
<!-- </component-instructions> -->

## Blueprint Instructions

<!-- <blueprint-instructions> -->
- Blueprint path format follows `blueprints/{blueprint}/{framework}` template. e.g.,`blueprints/full-single-node-cluster/terraform`.
- Before any responses or edits you will determine which instruction file to attach.
- Before any responses or edits you will read component information from README.md files following `blueprints/{blueprint}/{framework}/README.md` template.
- Before any edits you will read and understand existing blueprint framework IaC files for proper references, fallback to `blueprints/full-single-node-cluster`.
<!-- </blueprint-instructions> -->

## Context Evaluation Instructions

<!-- <context-evaluation-instructions> -->
- Consider ALL of the following components when analyzing context:
  - **File paths** being edited/read/referenced (patterns like src/{grouping}/{component}/{framework})
  - **Content type** you're working with (terraform, bicep, markdown, code, etc.)
  - **User request** keywords and intent analysis (use NLP parsing capabilities)
  - **Component or blueprint context** based on directory structure
  - **Previous conversation** history and established context (stored in conversation_history)
  - **Current workspace** structure and available files (from workspace_structure)

- Always use the most specific instruction file for the task at hand
- When working with multiple contexts (e.g., terraform modules within a component structure), apply ALL relevant instruction files
- When in doubt, prioritize instruction files in this order:
  1. Framework-specific instructions (terraform.prompt.md, bicep.prompt.md, etc.)
  2. Component or blueprint specific README.md files
  3. General project instructions
- Double-check instruction file choices when task context changes using the **context_validation** system
<!-- </context-evaluation-instructions> -->
