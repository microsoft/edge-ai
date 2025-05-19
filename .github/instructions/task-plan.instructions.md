---
applyTo: '**/.copilot-tracking/plans/**'
---

# Task Planner and Implementer Instructions

You will ALWAYS think hard about task planning implementation instructions and established conventions.
You will ALWAYS search content from `**./.copilot-tracking/**` to help you understand and update the plan-file and notes-file.

You will ONLY implement changes when you have a full plan-file and a notes-file.

The DEFINITION of a task for your purpose will be ANY and ALL changes to the codebase (excluding changing plan-file or notes-file).
This includes small simple changes that touch a single line of code all the way up to large complex changes that can change many files or folders.
The user should be able to help you break it down into manageable parts.

- IMPORTANT, You will NOT change ANY code until you've been EXPLICITLY told to implement the plan or change code.
- You will be creating and/or updating a plan-file and a notes-file.
- You will ALWAYS use the plan-file and the notes-file when making ANY and ALL code changes.

When you are given a plan-file or a notes-file, you will ALWAYS do the following:

- You will read and understand all of the plan-file and all of the notes-file
- If the user has told you any of the following, then you will follow the implement-plan-file instructions:
  - Implement the plan
  - Continue implementing the plan
  - Finish implementing the plan
- If the user has told you to verify the plan
  - You will follow the instructions in the planning-process and make updates to the existing plan-file and notes-file
- If the user has told you to verify your implementation of the plan
  - You will review all of the completed phase tasks within the plan-file against the already implemented code.
  - You will verify all of the changes are correct for these completed phase tasks in the notes-file.
  - You will verify that you made the correct changes and make any necessary updates to the plan-file or notes-file.
  - You will NOT make any code changes.

## Core Responsibilities and User Interactions

When provided with a plan-file or notes-file, you MUST ALWAYS:

1. Read and understand ALL contents of both files
2. Take appropriate action based on user instruction:
   - "Implement the plan" / "Continue implementing" / "Finish implementing" → Follow implementation instructions
   - "Verify the plan" → Update plan-file and notes-file following planning process
   - "Verify your implementation" → Review completed tasks against implemented code without making new changes

You WILL NEVER change ANY code until:
- Both plan-file and notes-file are complete
- You have been EXPLICITLY instructed to implement the plan

## Planning Process

<!-- <planning-process> -->
The planning process involves creating and updating the plan-file and notes-file based on the task.

1. Before taking any action, you will do the following:

- You will verify that you were given a task file or a prompt that has all of the relevant information needed to complete a task.
- Otherwise, you will ask the user:
  - "What is the task you want to accomplish? Please attach any relevant information to the conversation."
    - The user can attach a task file, instruction files, relevant project files, or a prompt.

2. If needed, create the plan-file with the title section matching the user's task.

3. Verify that you have answers for all of these questions, otherwise, discover the information yourself and ask the user when needed:

- Do I know the expected outcome of the task?
- Do I have the full scope of the task?
- Do I know all specific requirements or constraints?
- Do I know all resources or references that I should consider?
- Do I have all examples that I can refer to?
- Do I know all external references or tools to use when researching and implementing this task?
- Do I know all specific tools and technologies when implementing this task?
- Do I know all of the files the should be changed?
- Do I know all of the files that I should create?
- Do I know all of the coding conventions and best practices that I need to follow for the task?
- Do I have all of the information to implement the task?

4. Follow update the plan-file accordingly.

5. Verify the plan-file includes required to complete the task.

6. Repeat steps 3-5 of the planning-process until the plan-file includes everything required to complete the task.

7. Inform the user that the plan-file and notes-file are ready for review.

8. Review any and all updated information in the plan-file or notes-file, for any updated information you will repeat steps 3-5 of the planning-process until the plan-file includes everything required to complete the task.

9. Inform the user that they can `/clear` their context if needed, and that they can now provide the plan-file and notes-file along with the task-planner.prompt.md to implement the plan.

10. You will await any further instruction from the user.
<!-- </planning-process> -->

## Plan File Format

<!-- <plan-file> -->
The purpose of the plan-file is for you to keep track of all of the relevant information and steps required to implement the task.
The plan-file MUST have all of the relevant information needed for you to implement the task completely.
The plan-file should include relevant links to files or folders, URLs, documentation, line numbers for code, etc.

CRITICAL REQUIREMENTS:
- MUST contain ALL information needed to implement the task completely
- DON'T include a link to a task file as they will be treated as ephemeral
- ALL required information for you to complete the task MUST be in the plan-file
- ALL file or folder paths should be relative to the root of the project
- When creating a plan, organize it into numbered phases (e.g., "## Phase 1: Setup Dependencies")
- Break down each phase into specific tasks, called phase tasks, with markdown checkboxes and numeric identifiers (e.g., "- [ ] Task 1.1: Add Dependencies")
- The plan is written into a markdown file `YYYYMMDD-task-plan.md` in the `./.copilot-tracking/plans` directory at the root.
<!-- </plan-file> -->

## Coding Notes File Format

<!-- <notes-file> -->
The purpose of the coding notes-file is to keep track of all changes for the task-plan. Once implementation of the task-plan is finished, coding notes-file will be used to create the release notes for this change.

- You will create the coding notes in the `./.copilot-tracking/notes` directory with the naming convention `<plan-file-name>-notes.md`
- The coding notes will include a link to the task-plan file.
<!-- <notes-entry> -->
- IMPORTANT, EVERY TIME you complete a phase task, you will create or update a notes entry in the coding notes-file for the plan and summarize the completed work
- The notes entry follows the notes-entry-template and MUST include:
  - Phase number and name
  - Completion date and time - Only filled out when the ENTIRE phase has been completed
  - Major files added, updated, removed
  - Major features added, updated, removed
<!-- </notes-entry> -->
<!-- </notes-file> -->

<!-- <notes-entry-template> -->
   ```markdown
   ## Phase <phase-number>: <phase-name>
   - Completed on: <current UTC date and time>
   - Completed by: <name of the person who completed the phase, not Copilot>

   ### Phase <phase-number>: Major files added, updated, removed
   <list of files and brief summary of changes>

   ### Phase <phase-number>: Major features added, updated, removed
   <list of features and brief summary of changes>

   ### Phase <phase-number>: Patterns, abstractions, data structures, algorithms, etc.
   <list of patterns, abstractions, data structures, algorithms, etc. and brief summary of changes>

   ### Phase <phase-number>: Governing design principles
   <list of design principles and brief summary of changes>
   ```
<!-- </notes-entry-template> -->

## Implementing a Plan File

<!-- <implement-plan-file> -->
When implementing a plan file, you MUST follow these CRITICAL requirements:

1. ALWAYS follow the plan-file step-by-step for implementing code changes
2. ALWAYS update the notes-file after making any changes
3. While implementing, you MUST:
   - Continue updating both plan-file and notes-file as needed
   - Continue researching and verifying all changes
   - ALWAYS follow coding conventions and best practices referenced in the plan-file

4. IMMEDIATELY after completing a phase task:
   - Update the plan-file to mark the checkbox (indicating completion)
   - Create or update the corresponding notes entry

5. When completing an ENTIRE phase:
   - Update the phase title to include `(Completed)`
   - Complete the "Completed on" field in the notes entry

6. Continue implementing until ALL phases are complete and notes-file is fully updated

7. If you discover ANY change that diverges from the plan-file, you MUST:
   - STOP all code changes IMMEDIATELY
   - Update the plan-file
   - Repeat planning process steps 3-5 to ensure plan completeness
   - Ask the user if you should continue and AWAIT instructions
<!-- </implement-plan-file> -->
