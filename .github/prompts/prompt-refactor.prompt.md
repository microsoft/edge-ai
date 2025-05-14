---
mode: 'agent'
---

# Prompt Refactor

- Your primary objective: Refactor the `${input:prompt}` file (or all files if a folder is specified) in the following way:
  - Condense all of the components of the file (prompts, instructions, conventions, best practices, guidelines, examples)
  - Improve all of the components of the file (clarity, repetition, additional markings, consistency, prompting terms)
  - Re-organize all of the components of the file (clarity, consistency, similar groupings)

- MANDATORY: If `${input:focus}` was provided:
  - Then, You MUST focus your refactoring ONLY on `${input:focus}`
  - Otherwise, You MUST refactor for everything (condense, improve, organization).

- SPECIAL CASE: If `${input:focus}` is `split`:
  - Then, You MUST focus your refactoring ONLY on splitting the `${input:prompt}` into a number of different files.

CRITICAL: The refactored file(s) MUST retain full efficacy as a prompt for You.

MANDATORY: Read and all steps from the `process` section below.
You MUST follow ALL steps in the `process` section below.

## Requirements for Improving Document

<!-- <requirements> -->

- You MUST review the `${input:prompt}` document in its entirety.
- You MUST fully understand the `${input:prompt}` document's purpose, content, and ALL its components (prompts, instructions, conventions, best practices, guidelines, examples).
- You MAY move, rename, add, or remove sections.
- You MAY remove examples or condense repeated/obvious content.
- CRITICAL: You MUST ensure that You will understand EVERYTHING when prompted with the refactored document later.
- You WILL NEVER add any new concepts that were not already present in the `${input:prompt}` document.
- You WILL NEVER alter the original purpose of examples. If examples are modified, their core meaning and structure MUST be preserved unless new instructions dictate otherwise. Redundant examples MAY be removed.
- You WILL NEVER add anything to the `${input:prompt}` that should go into the report, this includes (but are not limited to): clarifying instructions, step-by-step plans, highlighting inconsistencies, string of thought.
  - You MUST keep this information in the report.
- ALL changes MUST contribute to refactoring the `${input:prompt}` document.
- You WILL ALWAYS remove any invisible or hidden unicode characters.
- You WILL ALWAYS make changes and improvements that follow prompting best practices. Key terms to use include (but are not limited to): You, WILL, MUST, DO, DON'T, ALWAYS, NEVER, EVERY, IMPORTANT, CRITICAL, MANDATORY.
- You WILL continue to use any markings for sections and examples for references, e.g., XML style `<!-- <example> --> <!-- </example> -->`.
- You MUST follow ALL Markdown best practices and conventions for this project for ALL changes. Refer to the project's `.mega-linter.yml` file and any other relevant documentation for these conventions.
- ALL Markdown links to sections MUST be updated if section names or locations change.

### Split File Additional Requirements

- If `${input:numFiles}` was provided then You MUST split the `${input:prompt}` into EXACTLY `${input:numFiles}`.
  - Otherwise, review `${input:prompt}` and suggest the number of files to split.
- Keep `{content-descriptor}` to 1-2 words.
- If the original file is named `document.prompt.md`, the split files (including the modified original) SHOULD be named:
  - `document.prompt.md` (original, now modified)
  - `document-{content-descriptor-1}.prompt.md`
  - `document-{content-descriptor-2}.prompt.md`
  - For example: `original-doc.prompt.md`, `original-doc-examples.prompt.md`, `original-doc-conventions.prompt.md`.
- If the original file is named `document.md`, the pattern is similar:
  - `document.md` (original, now modified)
  - `document-{content-descriptor-1}.md`
  - For example: `original-doc.md`, `original-doc-examples.md`.
- The original `${input:prompt}` split file MUST be the ONLY file to include references to all other split files, using standard Markdown file references near the top of the document.
- NO other split files WILL reference other split files.
- NO split file WILL describe itself as a split file or reference the splitting process.
- You MUST ensure that when all split files are used together, they WILL provide the EXACT same understanding as the original document.

<!-- </requirements> -->

## Process for Improving Document

<!-- <process> -->

1. MANDATORY: BEFORE You do ANYTHING, You MUST manage the report file with the following steps:
  1.1. The report file WILL be named `.copilot-tracking/reports/${name_of_input_prompt_file}.report.md`. `${name_of_input_prompt_file}` is the base name of the `${input:prompt}` file (e.g., if `${input:prompt}` is `/path/to/your/file.md`, then `${name_of_input_prompt_file}` is `file.md`).
  1.2. You WILL ensure this report file exists. If it does not exist, You WILL create it. If it already exists, You WILL continue from the existing report.
  1.3. You MUST only append to this report. If the report already exists, You WILL add new sections or update existing ones as necessary. You MUST NEVER remove prior content.
  1.4. You WILL add to this report file your detailed step-by-step plan.
  1.5. If You find any inconsistencies or conflicting instructions/examples in the `${input:prompt}` document, You MUST provide details in a dedicated section within the report file.
2. CRITICAL: You MUST completely review and strictly adhere to all instructions within the `Requirements for Improving Document` section.
3. MANDATORY: You WILL update the corresponding report file with your step-by-step plan for the changes that you will make.
4. Then, You WILL make the changes to the `${input:prompt}` document(s).
  - IMPORTANT: You MUST ensure that all of your changes meticulously meet ALL requirements.
  - IMPORTANT: You MUST continually review your changes against the report file.
5. Once You have finished making ALL changes to the `${input:prompt}` document(s), You MUST update the corresponding report file with a comprehensive log of everything that You actually did.
6. You WILL review the report file and make any updates that You might have missed into the `${input:prompt}` document(s).
7. You MUST repeat steps 4-6 until all changes have been made and all requirements were followed.
8. Finally, You WILL review the report file and verify that all changes made to the `${input:prompt}` document(s) were done correctly and completely.
9. Once ALL changes are made and You are finished, You WILL delete the report file.

<!-- </process> -->
