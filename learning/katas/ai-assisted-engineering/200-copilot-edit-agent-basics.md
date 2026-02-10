---
title: 'Kata: 200 - Copilot Edit Agent Basics'
description: Learn GitHub Copilot Edit agent fundamentals including agent selection, @workspace context, #-file mentions, and coordinated multi-file editing for consistent codebase changes
author: Edge AI Team
ms.date: 2025-01-24
kata_id: ai-assisted-engineering-200-copilot-edit-agent-basics
kata_category:
  - ai-assisted-engineering
kata_difficulty: 2
estimated_time_minutes: 60
learning_objectives:
  - Activate GitHub Copilot Edit agent using the mode selector dropdown
  - Provide context for multi-file edits using @workspace and #-file mentions
  - Apply basic refactoring patterns using Edit agent
  - Understand when to use @workspace vs #-mentions for file discovery
prerequisite_katas:
  - ai-assisted-engineering-100-copilot-modes
technologies:
  - GitHub Copilot
  - GitHub Copilot Chat
  - Chat Edit Mode
  - VS Code
success_criteria:
  - Activate Edit agent using the mode selector dropdown in Chat panel
  - Successfully coordinate edits across 3+ related files using @workspace or #-mentions
  - Apply basic refactoring patterns with Edit agent assistance
  - Demonstrate understanding of when to use @workspace vs #-file mentions
ai_coaching_level: guided
scaffolding_level: medium-heavy
common_pitfalls:
  - "Using @workspace without directory scope - be specific with '@workspace In directory/path/'"
  - "Using #-mentions for many files when @workspace would be more efficient"
  - "Not providing enough context in prompts - specify exact changes needed across files"
  - "Forgetting to review suggested changes before accepting - always validate multi-file diffs in chat"
requires_azure_subscription: false
requires_local_environment: true
tags:
  - ai-assisted-engineering
search_keywords:
  - copilot edit agent
  - agent selector
  - workspace context
  - multi-file editing
  - coordinated edits
  - github copilot basics
---

## Quick Context

**You'll Learn**: Activate Edit agent using the mode selector dropdown in the Chat panel; provide context for multi-file edits using @workspace and #-file mentions; execute multi-file configuration updates; apply basic refactoring patterns including function extraction and variable renaming; and recognize when to use Edit agent vs. Ask agent.
**Real Challenge**: You're a platform engineer working on a microservices architecture where shared configuration parameters appear across 5 different service files. Your team discovered a timeout setting needs updating from 30 to 60 seconds. Manual updates are error-prone and time-consuming - you risk missing files or introducing typos. Additionally, you've identified duplicated utility functions that should be extracted to a shared module.

This kata teaches you to use Edit agent with @workspace context to coordinate these changes efficiently, accurately, and confidently.

## Essential Setup

**Required Tools**:

- VS Code with GitHub Copilot extension installed and active subscription
- GitHub Copilot Chat panel accessible (Ctrl+Alt+I / Cmd+Alt+I)
- Agent selector visible in Chat panel for switching between Ask/Edit/Plan/Agent modes
- Completion of GitHub Copilot Modes kata (ai-assisted-engineering-100-copilot-modes)

**Required Knowledge**:

- Basic understanding of file navigation, project structure, and code organization
- Familiarity with TypeScript or JavaScript for refactoring exercises
- Understanding of @workspace context for broad file discovery
- Familiarity with #-file mentions for specific file targeting

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on Edit Mode Basics kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Edit Agent Activation and File Selection

<!-- AI_COACH: This phase introduces Edit agent activation and context provision fundamentals. If learners struggle with context provision, guide them to think about file relationships—which files share related concepts or configurations? Encourage starting with 2-3 files using #-mentions before scaling up to @workspace for broader discovery. -->
<!-- AI_COACH: Remind them that Edit agent uses @workspace for automatic file discovery and #-mentions for explicit file targeting. Unlike Ask agent which has full workspace context by default, you explicitly choose your context provision strategy in Edit agent. -->

Edit agent is specifically designed for coordinated multi-file changes. Understanding activation methods and file selection strategies is fundamental to using Edit agent effectively.

#### Activating Edit Agent

Edit agent is one of four built-in custom agents selectable via dropdown in the Chat panel:

**Custom Agent Selector** (Standard activation method):

1. Open GitHub Copilot Chat panel:
   - Windows/Linux: `Ctrl+Alt+I`
   - macOS: `Cmd+Alt+I`
2. Locate the mode selector dropdown at the top of the Chat panel
3. Click the dropdown (defaults to "Ask")
4. Select "Edit" from the list of available modes
5. The chat interface remains in the same panel - no separate window opens

**Available Custom Agents** in the dropdown:

- **Ask**: Question-answering and code explanations (default mode)
- **Edit**: Multi-file editing and coordinated changes
- **Plan**: Breaking down complex tasks into steps (Insiders only)
- **Agent**: Autonomous multi-step task execution

**Use Edit agent when**: You need to make consistent changes across multiple related files

#### Context Provision Strategies

Edit agent uses chat context mechanisms instead of explicit file selection. Provide context strategically:

**@workspace for Broad Discovery**:

- Use when you're unsure which files contain the pattern you need to change
- Copilot searches your codebase and discovers relevant files automatically
- Optionally scope to specific directory: `@workspace In directory/path/`
- **Best for**: Finding all files with a specific pattern, configuration, or concept

**#-file Mentions for Known Files**:

- Use when you know exactly which files need changes
- Explicitly list each file using # or #file: prefix
- Provides precise control over context scope
- **Best for**: Known file sets with clear relationships (2-5 files)

**Context Provision Best Practices**:

1. **Start with @workspace**: Use @workspace when uncertain about file locations
2. **Scope @workspace searches**: Add directory path to narrow discovery: `@workspace In src/services/`
3. **Use #-mentions for precision**: List specific files when you know exactly what needs changing
4. **Avoid over-mentioning**: Don't list many files when @workspace would discover them automatically

#### Practice Exercise: Configuration Updates Across Services

Create a realistic microservices configuration scenario and practice coordinated updates with Edit Mode.

**Steps**:

1. **Create sample service configurations**
   - [ ] Check current git status: `git status` in terminal to see clean state
   - [ ] Navigate to project infrastructure: `src/000-cloud/` contains real Terraform components
   - [ ] Identify target components for practice:
     - `010-security-identity/terraform/variables.tf` - Identity infrastructure
     - `020-observability/terraform/variables.tf` - Monitoring configuration
     - `030-data/terraform/variables.tf` - Data services
   - **Pro tip**: These are real production Terraform files - all changes will be reverted with `git restore` after practice
   - [ ] **Expected result**: You can open and view these three real variables.tf files, and git status shows clean working directory

2. **Activate Edit agent via mode selector**
   - [ ] Open GitHub Copilot Chat panel: `Ctrl+Alt+I` / `Cmd+Alt+I`
   - [ ] Click the mode selector dropdown at the top of the Chat panel
   - [ ] Select "Edit" from the dropdown menu (changes from default "Ask" mode)
   - [ ] The Chat panel remains in the same location - you're now in Edit agent mode
   - [ ] **Expected result**: Chat panel shows "Edit" mode selected in dropdown

3. **Apply coordinated description additions with @workspace**
   - [ ] In the Chat panel (Edit mode), type prompt:

   ```text
   @workspace In src/000-cloud/ find all variables.tf files that have a 'tags' variable. For each one, add a description explaining that tags are used for resource organization and cost tracking
   ```

   - [ ] Press Enter and wait for Copilot to discover files and generate changes
   - [ ] Copilot automatically discovers multiple variables.tf files across components
   - [ ] Review the suggested changes in the chat diff view
   - **Pro tip**: Always review multi-file diffs in chat before accepting - verify consistency and correctness across real infrastructure files
   - [ ] Verify that only `description` fields are added, no variable types or defaults are changed
   - [ ] Click "Accept" button in the chat to apply changes
   - [ ] **Expected result**: Multiple variables.tf files now have helpful description comments on tags variables

4. **Practice #-file mentions for specific file targeting**
   - [ ] In the Chat panel (still in Edit mode), type prompt with explicit file mentions:

   ```text
   #src/000-cloud/010-security-identity/terraform/variables.tf #src/000-cloud/020-observability/terraform/variables.tf Add validation block to 'environment' variable requiring it to be one of: dev, test, prod
   ```

   - [ ] Review and accept changes in chat
   - **Validation checkpoint**: Can you explain when to use @workspace vs #-file mentions?
   - [ ] **Expected result**: Two mentioned variables.tf files now have validation blocks on environment variable, other files unchanged

5. **Test @workspace with broader scope**
   - [ ] In the Chat panel (Edit mode), type broader @workspace prompt:

   ```text
   @workspace In src/000-cloud/030-data/terraform/variables.tf add helpful descriptions to any variables that are missing them, explaining their purpose in the data infrastructure component
   ```

   - [ ] Copilot discovers the data component variables file
   - [ ] Review suggested description additions in chat diff view
   - [ ] Click "Accept"
   - [ ] **Expected result**: The variables.tf file now has improved documentation with description fields added where missing

6. **Practice rejection workflow in chat**
   - [ ] In Chat panel (Edit mode), type:

   ```text
   @workspace In src/000-cloud/ change all 'location' variable default values to 'westus3'
   ```

   - [ ] Review the suggested changes in chat diff view
   - [ ] Click "Discard" or simply don't click "Accept" - this demonstrates safely rejecting changes
   - **Pro tip**: This is particularly important with real infrastructure files - you can explore changes without risk
   - [ ] **Expected result**: No changes applied - infrastructure files remain unchanged

7. **Clean up: Reset all changes with git restore**
   - [ ] Run in terminal: `git status` to see all modified variables.tf files
   - [ ] Run: `git restore src/000-cloud/*/terraform/variables.tf` to revert all practice changes
   - [ ] Run: `git status` again to verify clean working directory
   - **Pro tip**: This git restore workflow lets you practice on real infrastructure safely
   - [ ] **Expected result**: All Terraform files back to original state, ready for actual development work

### Task 2: Coordinated Changes and Basic Refactoring

<!-- AI_COACH: Phase 2 builds on file selection with practical coordination patterns. When learners encounter refactoring challenges, encourage them to break down the task: What's the pattern to change? Which files share this pattern? What's the specific transformation needed? Edit Mode excels when the request is clear and file relationships are explicit. -->

> **Note**: This task uses TypeScript practice code to teach refactoring patterns that transfer directly to infrastructure-as-code work. The skills of coordinated variable renaming, function extraction, and import consistency apply equally to Terraform, Bicep, and other IaC languages.

Edit Mode's power extends beyond simple configuration updates to include coordinated refactoring patterns. This phase teaches you to apply Edit Mode to variable renaming, function extraction, and import consistency.

#### Coordinated Variable Renaming

Variable renaming across module boundaries is a common refactoring need. Edit Mode can update variable declarations, usages, and references consistently across files.

**Pattern**: Rename a shared concept across multiple modules

**When to use Edit Mode** (vs. language-specific refactoring):

- Variable appears in different files without language server connection
- Renaming affects configuration files, not just code
- Updates needed in comments, documentation, or strings
- Language-specific rename tools don't cover all file types

**Example Scenario**: Rename `maxRetries` to `maxAttempts` across 3 modules that share this configuration concept but aren't directly connected by imports.

#### Basic Refactoring Patterns with Edit Mode

**Extract Shared Function Pattern**:

1. Identify duplicated logic in multiple files
2. Create shared utility file
3. Use Edit Mode to: move function to utility, add exports, update original files with imports

**Move Constants to Shared Configuration**:

1. Find constants duplicated across modules
2. Create shared constants file
3. Use Edit Mode to: extract constants, export from shared file, update imports in consuming files

**Update Import Statements Consistently**:

1. Refactor changes module structure
2. Multiple files import from old location
3. Use Edit Mode to: update import paths consistently across all consuming files

#### Practice Exercise: Extract Shared PowerShell Function

Apply Edit Mode to extract duplicated PowerShell functionality into a shared module with coordinated import updates.

**Steps**:

1. **Examine existing scripts with duplicated logic**
   - [ ] Run `git status` to confirm clean working tree
   - [ ] Open `scripts/Validate-MarkdownFrontmatter.ps1` and locate the `Get-MarkdownFrontmatter` function (starts around line 28)
   - [ ] Review the function's purpose: Extracts YAML frontmatter from markdown files
   - [ ] Note that this function is self-contained and could be useful in other scripts
   - [ ] **Expected result**: Understanding of the frontmatter parsing logic that will be extracted

2. **Create shared module structure**
   - [ ] Create directory: `scripts/shared/`
   - [ ] Create empty file: `scripts/shared/Markdown-Utils.psm1`
   - [ ] **Expected result**: Module file ready to receive extracted function

3. **Prepare Edit agent for coordinated refactoring**
   - [ ] Open GitHub Copilot Chat: `Ctrl+Alt+I` / `Cmd+Alt+I`
   - [ ] Select "Edit" mode from the mode selector dropdown
   - [ ] **Expected result**: Chat panel in Edit mode, ready for multi-file PowerShell refactoring

4. **Extract function to shared module with #-file mentions**
   - [ ] In Chat panel (Edit mode), enter prompt with explicit file mentions:

   ```text
   #scripts/Validate-MarkdownFrontmatter.ps1 #scripts/shared/Markdown-Utils.psm1 Extract the Get-MarkdownFrontmatter function from Validate-MarkdownFrontmatter.ps1 to the shared module Markdown-Utils.psm1. Add Export-ModuleMember at the end of the module file to export Get-MarkdownFrontmatter. Update Validate-MarkdownFrontmatter.ps1 to import the module with: Import-Module "$PSScriptRoot/shared/Markdown-Utils.psm1" -Force
   ```

   - [ ] Wait for Copilot to generate coordinated changes
   - [ ] Review changes in chat diff view across both files — **Markdown-Utils.psm1**: New `Get-MarkdownFrontmatter` function with `Export-ModuleMember`, **Validate-MarkdownFrontmatter.ps1**: Import statement added, function definition removed
   - **Pro tip**: Check that the module path uses `$PSScriptRoot` for relative importing
   - [ ] **Expected result**: Chat shows clear diff with function extraction and module import addition

5. **Validate refactoring correctness in chat diff**
   - [ ] In chat diff view, verify `Markdown-Utils.psm1` contains the complete `Get-MarkdownFrontmatter` function
   - [ ] Verify `Markdown-Utils.psm1` ends with `Export-ModuleMember -Function Get-MarkdownFrontmatter`
   - [ ] Verify `Validate-MarkdownFrontmatter.ps1` has the import statement near the top
   - [ ] Verify the function definition is removed from `Validate-MarkdownFrontmatter.ps1`
   - [ ] Verify the script still calls `Get-MarkdownFrontmatter` where needed (around line 300)
   - **Validation checkpoint**: Does the refactoring maintain the same behavior while creating reusable module?
   - [ ] Click "Accept" in chat to execute the coordinated refactoring
   - [ ] **Expected result**: Shared module function with script correctly importing and using it

6. **Test the refactored script**
   - [ ] In Chat panel (still in Edit mode), ask for validation:

   ```text
   #scripts/Validate-MarkdownFrontmatter.ps1 Can you verify that all calls to Get-MarkdownFrontmatter are still present and that the Import-Module statement will work correctly?
   ```

   - [ ] Review Copilot's analysis
   - **Pro tip**: Edit agent can validate refactoring without executing code
   - [ ] If issues found, accept suggested fixes; if correct, proceed to next step
   - [ ] **Expected result**: Confirmation that refactoring is complete and correct

7. **Practice module reuse with another script**
   - [ ] In Chat (Edit mode), use #-mention to add the same import to another script:

   ```text
   #scripts/Generate-DocsSidebar.ps1 #scripts/shared/Markdown-Utils.psm1 Add an import for the Markdown-Utils module at the top of Generate-DocsSidebar.ps1 using: Import-Module "$PSScriptRoot/shared/Markdown-Utils.psm1" -Force
   ```

   - [ ] Review and accept in chat
   - [ ] **Expected result**: Understanding that shared modules can be imported into multiple scripts

8. **Clean up with git restore**
   - [ ] Run `git status` to see all modified and new files
   - [ ] Run `git restore scripts/` to undo script changes
   - [ ] Run `Remove-Item scripts/shared/ -Recurse -Force` to remove the created module directory
   - [ ] Run `git status` again to verify clean working tree
   - [ ] **Expected result**: All practice changes reverted, workspace back to original state

#### Coordinated Module Import Updates

When module structure changes, import statements need consistent updates across consuming scripts.

**Scenario**: You renamed `shared/Markdown-Utils.psm1` to `shared/Frontmatter-Utils.psm1`

**Edit Agent Workflow**:

1. Activate Edit mode in Chat panel
2. Use @workspace to discover all scripts importing the module:

   ```text
   @workspace In scripts/ Update all Import-Module statements from 'Markdown-Utils.psm1' to 'Frontmatter-Utils.psm1'
   ```

3. Copilot discovers files with the import and suggests coordinated changes
4. Review path consistency in chat diff view
5. Apply changes

**Practice**:

- [ ] Manually rename `scripts/shared/Markdown-Utils.psm1` to `scripts/shared/Frontmatter-Utils.psm1` (if it exists from previous practice)
- [ ] Open Chat panel in Edit mode
- [ ] Use @workspace to coordinate import statement updates:

   ```text
   @workspace In scripts/ All Import-Module statements should now import Frontmatter-Utils.psm1 instead of Markdown-Utils.psm1 since the module was renamed
   ```

- [ ] Review suggested import path changes in chat diff view
- [ ] Accept changes and verify all import statements are correct
- [ ] Run `git restore scripts/` and `Remove-Item scripts/shared/ -Recurse -Force` to clean up
- [ ] **Expected result**: All scripts correctly import from the renamed module, then reset with git

## Completion Check

**You've Succeeded When**:

- [ ] You can activate Edit agent using the mode selector dropdown in the Chat panel
- [ ] You successfully coordinated configuration updates across 3+ service files using @workspace context and #-file mentions
- [ ] You applied the extract-function refactoring pattern with Edit agent, creating shared utilities and updating imports
- [ ] You understand the difference between @workspace context (broad discovery) and #-file mentions (specific targeting)
- [ ] You practiced the review-in-chat-then-Accept workflow and successfully discarded unwanted changes
- [ ] You completed both practice exercises with consistent multi-file results validated by manual inspection

**Success Criteria Validation**:

- Can you explain when to use Edit agent vs. Ask agent for multi-file scenarios?
- Can you describe how to activate Edit agent and provide context using @workspace and #-mentions?
- Have you successfully extracted a shared function and updated multiple consuming files?
- Do you understand context provision best practices (@workspace for discovery, #-mentions for known file sets)?

**Next Steps**: [200 - Edit Agent for IaC Patterns][kata-200-iac] — Apply Edit Agent to Infrastructure as Code workflows

---

## Reference Appendix

### Help Resources

- [GitHub Copilot Edit Agent Documentation](https://docs.github.com/copilot/using-github-copilot/editing-code-with-github-copilot) - Official Edit Agent guide
- [VS Code Multi-cursor and Selection](https://code.visualstudio.com/docs/editor/codebasics#_multiple-selections-multicursor) - File selection techniques
- [Refactoring Patterns](https://refactoring.guru/refactoring/catalog) - Common refactoring patterns that work well with Edit Agent

### Professional Tips

- **Start Small**: Begin with 2-3 files using #-mentions to understand Edit agent behavior before scaling with @workspace
- **Choose Context Strategy**: Use @workspace for discovery when file set is unknown; use #-mentions when targeting known files
- **Review Before Accept**: Always validate multi-file changes in the chat diff view before accepting
- **Use Explicit Prompts**: Specify exact changes needed across files to improve Edit agent accuracy
- **Incremental Updates**: Edit agent works for both bulk refactoring and incremental updates to existing patterns
- **Scope @workspace**: Narrow @workspace with directory paths (`@workspace In src/`) to improve discovery relevance

### Troubleshooting

**Problem**: @workspace discovers too many unrelated files
**Solution**: Scope @workspace with directory path: `@workspace In specific/directory/` to narrow discovery

**Problem**: Import paths incorrect after refactoring
**Solution**: Verify relative paths in the chat diff view before accepting; check directory structure matches expectations

**Problem**: Changes not applied to all mentioned files
**Solution**: Ensure prompt explicitly mentions all files (with #-mentions) or provides clear @workspace scope; review Copilot's interpretation

**Problem**: #-file mentions not working
**Solution**: Verify file paths are correct and files exist; use autocomplete (type # in chat) to select files

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->

[kata-200-iac]: /learning/katas/ai-assisted-engineering/200-copilot-edit-agent-iac-patterns.md
