---
title: "Kata: 100 - Inline Chat Quick Edits"
description: Learn GitHub Copilot's inline chat with Ctrl+I for rapid selection-based edits, refactoring, and convention-aware modifications to Terraform and Bicep code
author: Edge AI Team
ms.date: 2025-01-25
kata_id: ai-assisted-engineering-100-inline-chat-quick-edits
kata_category:
  - ai-assisted-engineering
kata_difficulty: 1
estimated_time_minutes: 30
learning_objectives:
  - Activate inline chat with Ctrl+I/Cmd+I for contextual code modifications
  - Perform selection-based scoped edits for precise refactoring without affecting surrounding code
  - Apply mode selection framework to choose between inline chat and panel-based Edit Mode
prerequisite_katas:
  - ai-assisted-engineering-100-inline-suggestions-basics
technologies:
  - GitHub Copilot
  - Terraform
  - Bicep
  - Visual Studio Code
success_criteria:
  - Use Ctrl+I for 5+ common IaC editing patterns without opening chat panel
  - Scope edits to selections to prevent unintended changes to surrounding code
  - Correctly choose inline chat vs Edit Mode based on modification complexity and scope
ai_coaching_level: guided
scaffolding_level: heavy
hint_strategy: progressive
common_pitfalls:
  - Using Edit Mode (Ctrl+Shift+I) when inline chat (Ctrl+I) would be faster for small edits
  - Making edits without selecting target code first, resulting in broad unintended changes
  - Not leveraging project instructions files for automatic convention compliance
  - Accepting inline chat suggestions without reviewing changes against project standards
requires_azure_subscription: false
requires_local_environment: true
tags:
  - ai-assisted-engineering
search_keywords:
  - inline-chat
  - ctrl-i
  - code-refactoring
  - selection-edits
  - copilot-modes
---

## Quick Context

You've written a Terraform resource but forgot to add required tags. Instead of manually typing the tags block, you select the resource, press **Ctrl+I** (or **Cmd+I** on Mac), type "add standard tags", and watch Copilot insert perfectly formatted tags—all without leaving your cursor position or opening a chat panel.

**Real Challenge**: IaC development involves constant small modifications: adding validation rules, updating variable defaults, converting `count` to `for_each`, extracting magic values into locals. Opening the full chat panel for these edits breaks flow. Inline chat (Ctrl+I) keeps you in the code while providing AI-powered editing.

**Your Task**: Learn Ctrl+I activation, selection-based scoping, and decision framework for choosing between inline chat vs. panel-based Edit Mode. You'll practice 5 common IaC editing patterns with real edge-ai Terraform examples.

## Essential Setup

**Required** (check these first):

- [ ] VS Code with GitHub Copilot extension installed, active subscription, and "Ready" status in status bar
- [ ] Completed 100 - Inline Suggestions Basics kata (prerequisite for inline chat patterns)
- [ ] Repository cloned to `/workspaces/edge-ai` with VS Code opened to workspace root
- [ ] Awareness of **Terraform Instructions File** (`.github/instructions/terraform.instructions.md`) — project conventions for Terraform naming patterns, resource structure, validation requirements, and component standards that Copilot reads automatically for convention-aware edits
- [ ] Time allocated: 30 minutes for inline chat activation and IaC editing practice

**Quick Validation**: Open any `.tf` file, select a resource block, press **Ctrl+I** (Windows/Linux) or **Cmd+I** (Mac). Inline chat box should appear directly in editor.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on 100 - Inline Chat Quick Edits kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Activate Inline Chat for Common IaC Edits (10 minutes)

**What You'll Do**: Practice Ctrl+I activation for 5 common IaC modification patterns—adding tags, validation rules, outputs, lifecycle rules, and locals—building muscle memory for inline editing.

**Steps**:

1. **Create** practice file with basic Terraform resource
   - [ ] Create file: `/workspaces/edge-ai/src/000-cloud/010-security-identity/terraform/practice-inline-chat.tf`
   - [ ] Copy this starter code:

     ```hcl
     resource "azurerm_key_vault" "main" {
       name                = "kv-example"
       location            = "eastus"
       resource_group_name = "rg-example"
       sku_name            = "standard"
       tenant_id           = "00000000-0000-0000-0000-000000000000"
     }
     ```

   - [ ] Save the file
   - **Pro tip**: Starting with simple code makes inline chat results easier to verify
   - [ ] **Expected result**: Saved Terraform file with basic Key Vault resource

2. **Add** standard tags using inline chat
   - [ ] Select the entire `azurerm_key_vault` resource block (click line number, drag to select all lines)
   - [ ] Press **Ctrl+I** (Windows/Linux) or **Cmd+I** (Mac)
   - [ ] Type in the inline chat box: `add tags for Environment, Project, and ManagedBy`
   - [ ] Press Enter to submit
   - [ ] Review the diff shown in editor (green additions)
   - [ ] Click **Accept** button or press **Ctrl+Enter** to apply changes
   - **Validation checkpoint**: Did Copilot add a `tags` block with the 3 requested attributes? Are they properly formatted?
   - [ ] **Expected result**: Key Vault resource now includes `tags` block with Environment, Project, and ManagedBy attributes

3. **Practice** inline chat with 4 more common patterns
   - [ ] **Add validation**: Select the resource, press Ctrl+I, type: `add validation ensuring name is 3-24 characters`
   - [ ] Review diff, click Accept
   - [ ] **Add output**: Place cursor after resource block, press Ctrl+I, type: `add output for key vault id`
   - [ ] Review diff, click Accept
   - [ ] **Add lifecycle rule**: Select resource, press Ctrl+I, type: `add lifecycle rule to ignore changes to tags`
   - [ ] Review diff, click Accept
   - [ ] **Extract to local**: Select the `name` attribute value, press Ctrl+I, type: `extract to local variable`
   - [ ] Review diff, click Accept
   - **Pro tip**: Inline chat remembers your previous edits—it can reference earlier changes in the same file
   - **Validation checkpoint**: Do you have validation, output, lifecycle, and local variable all added via Ctrl+I?
   - [ ] **Expected result**: Complete Terraform file with 5 modifications, all performed through inline chat

### Task 2: Selection-Based Scoped Edits (10 minutes)

**What You'll Do**: Learn to scope inline chat edits to specific selections, preventing unintended changes to surrounding code. Practice 5 patterns: adding defaults, extracting variables, converting count to for_each, tagging consistency, and adding descriptions.

**Steps**:

1. **Create** multi-resource file for scoped editing practice
   - [ ] Create file: `/workspaces/edge-ai/src/000-cloud/020-observability/terraform/practice-scoped-edits.tf`
   - [ ] Copy this starter code with 3 separate resources:

     ```hcl
     resource "azurerm_log_analytics_workspace" "main" {
       name                = "law-example"
       location            = "eastus"
       resource_group_name = "rg-example"
     }

     resource "azurerm_application_insights" "main" {
       name                = "ai-example"
       location            = "eastus"
       resource_group_name = "rg-example"
       application_type    = "web"
     }

     resource "azurerm_monitor_action_group" "main" {
       name                = "ag-example"
       resource_group_name = "rg-example"
       short_name          = "ag-ex"
     }
     ```

   - [ ] Save the file
   - **Pro tip**: Multiple resources let you verify inline chat only modifies your selection
   - [ ] **Expected result**: File with 3 distinct Azure monitoring resources

2. **Scope** edits to first resource only using selection
   - [ ] Select **only** the `azurerm_log_analytics_workspace` resource (first block)
   - [ ] Press Ctrl+I, type: `add retention_in_days = 30 and sku = "PerGB2018"`
   - [ ] Review diff—verify changes **only** appear in log analytics workspace, not other resources
   - [ ] Click Accept
   - **Validation checkpoint**: Did Application Insights and Monitor Action Group remain unchanged?
   - [ ] **Expected result**: Only log analytics workspace modified, other resources untouched

3. **Practice** scoped selections with 4 more precise patterns
   - [ ] **Add defaults to variables block**: Create variable block above resources:

     ```hcl
     variable "environment" {
       type = string
     }
     ```

   - [ ] Select only the `variable "environment"` block, press Ctrl+I, type: `add description and default value of "dev"`
   - [ ] Review diff (should only affect variable block), click Accept
   - [ ] **Convert count to for_each**: In `azurerm_application_insights`, select only the `application_type` line, press Ctrl+I, type: `change this to use a map variable instead of hardcoded value`
   - [ ] Review suggested changes, click Accept
   - [ ] **Consistent tagging**: Select all 3 resources together, press Ctrl+I, type: `add consistent tags block to all selected resources with Environment and Project`
   - [ ] Review diff (should add tags to all 3), click Accept
   - [ ] **Add descriptions**: Select all 3 resources, press Ctrl+I, type: `add description comments above each resource explaining its purpose`
   - [ ] Review diff, click Accept
   - **Pro tip**: Selection size controls edit scope—single line, single block, multiple blocks, or entire file
   - **Success check**: Can you intentionally scope inline chat to exactly the code you want modified?
   - [ ] **Expected result**: File with targeted modifications to variables, type changes, consistent tags, and descriptions

### Task 3: Mode Selection and Convention-Aware Edits (10 minutes)

**What You'll Do**: Build decision framework for choosing inline chat (Ctrl+I) vs. Edit Mode (Ctrl+Shift+I), then practice convention-aware edits that automatically follow project standards from `.github/instructions/`.

**Steps**:

1. **Learn** the decision framework for mode selection
   - [ ] Read this comparison — **Inline Chat (Ctrl+I)**: Single file, small edits, selection-based, stays in editor, no file picker — **Edit Mode (Ctrl+Shift+I)**: Multi-file changes, large refactorings, shows file picker, opens panel
   - [ ] Open the Terraform Instructions File (see Essential Setup above)
   - [ ] Skim the file to understand terraform conventions (naming, structure, validation patterns)
   - **Pro tip**: Copilot reads `.github/instructions/` automatically—inline chat applies these conventions without you specifying them
   - **Validation checkpoint**: Can you explain when to use Ctrl+I vs. Ctrl+Shift+I?
   - [ ] **Expected result**: Clear mental model of mode selection based on edit scope

2. **Test** convention-aware editing with component-standard patterns
   - [ ] Create file: `/workspaces/edge-ai/src/000-cloud/050-networking/terraform/practice-conventions.tf`
   - [ ] Add basic resource:

     ```hcl
     resource "azurerm_virtual_network" "main" {
       name                = "vnet-example"
       location            = "eastus"
       resource_group_name = "rg-example"
       address_space       = ["10.0.0.0/16"]
     }
     ```

   - [ ] Select the resource, press Ctrl+I, type: `refactor this to match edge-ai component patterns`
   - [ ] Review the diff—Copilot should suggest changes based on Terraform Instructions standards
   - [ ] Click Accept
   - **Validation checkpoint**: Did inline chat apply project naming conventions automatically?
   - [ ] **Expected result**: Virtual network resource refactored to match component conventions without you specifying them

3. **Apply** mode selection framework to 5 realistic scenarios
   - [ ] **Scenario A**: "Add lifecycle rule to single resource" → Decision: _______ (Ctrl+I or Ctrl+Shift+I?)
   - [ ] **Scenario B**: "Rename variable across 3 component files" → Decision: _______ (Ctrl+I or Ctrl+Shift+I?)
   - [ ] **Scenario C**: "Extract repeated locals block in current file" → Decision: _______ (Ctrl+I or Ctrl+Shift+I?)
   - [ ] **Scenario D**: "Refactor entire module structure with new dependencies" → Decision: _______ (Ctrl+I or Ctrl+Shift+I?)
   - [ ] **Scenario E**: "Add output block to current file" → Decision: _______ (Ctrl+I or Ctrl+Shift+I?)
   - [ ] **Answers**: A=Ctrl+I (single file, small), B=Ctrl+Shift+I (multi-file), C=Ctrl+I (single file), D=Ctrl+Shift+I (large refactor), E=Ctrl+I (single file)
   - **Success check**: Can you correctly classify edit scenarios by mode without hesitation?
   - [ ] **Expected result**: Confident decision-making for inline chat vs. Edit Mode selection

## Completion Check

**You've Succeeded When**:

- [ ] Activated inline chat with Ctrl+I for 5+ common IaC modifications without opening chat panel
- [ ] Scoped edits to specific selections preventing unintended changes to surrounding code
- [ ] Used selection-based editing for precise refactoring patterns
- [ ] Applied mode selection framework correctly to 5 realistic scenarios
- [ ] Leveraged convention-aware editing that reads `.github/instructions/` automatically

**Test your understanding** (try without looking at notes):

- [ ] **Keyboard shortcut**: What's the difference between Ctrl+I and Ctrl+Shift+I?
- [ ] **Scoping**: How do you ensure inline chat only modifies one resource in a multi-resource file?
- [ ] **Mode selection**: When would you use Edit Mode instead of inline chat?
- [ ] **Convention awareness**: Why do inline chat edits automatically follow project standards?

**Confidence check**:

- [ ] I can perform common IaC edits with Ctrl+I faster than manual typing or Edit Mode
- [ ] I understand how selection size controls edit scope
- [ ] I can choose the right mode (inline vs. panel) based on edit complexity

**Next Steps**: Continue to **100 - AI Development Fundamentals** to learn about prompts, instructions, and custom agents, or jump to **100 - Copilot Modes** to learn Ask, Edit, and Agent mode workflows.

---

## Reference Appendix

### Help Resources

**Core Resources**:

- [GitHub Copilot Inline Chat](https://docs.github.com/en/copilot/using-github-copilot/asking-github-copilot-questions-in-your-ide#asking-questions-using-inline-chat) - Official documentation
- [VS Code Copilot Features](https://code.visualstudio.com/docs/editor/github-copilot) - Editor integration guide
- [Terraform Best Practices](https://www.terraform.io/docs/language/syntax/style.html) - HashiCorp style guide

**Project Resources**:

- Terraform Instructions: See Essential Setup section for full path and description
- Bicep Instructions: `.github/instructions/bicep.instructions.md` - Bicep standards
- Component Structure: `src/README.md` - Component organization patterns

### Professional Tips

- Default to inline chat (Ctrl+I) for single-file edits; use Edit Mode (Ctrl+Shift+I) only for multi-file changes
- Always select target code before pressing Ctrl+I to scope edits precisely
- Inline chat reads open files and `.github/instructions/` for context—leverage this for convention compliance
- Review diffs before accepting—inline chat can make unintended changes if your prompt is ambiguous
- Use natural language prompts: "add tags", "extract to variable", "convert to for_each" work better than technical jargon

### Troubleshooting

**Issue**: Inline chat modifies wrong code or too much code

- **Quick Fix**: Ensure you've selected the exact code to modify before pressing Ctrl+I. If selection is missing, Copilot uses cursor position and may infer broader scope. Always verify selection highlighting before submitting prompt.

**Issue**: Ctrl+I doesn't open inline chat box

- **Quick Fix**: Verify Copilot extension is active (status bar icon). Check that your cursor is inside a code file (not settings or output panel). On Mac, ensure Cmd+I isn't mapped to another command in VS Code keyboard shortcuts.

**Issue**: Inline chat suggestions don't match project conventions

- **Quick Fix**: Ensure `.github/instructions/terraform.instructions.md` is present in workspace. Open the instructions file in a tab—Copilot reads open files for stronger context. Add more specific prompts like "following edge-ai component patterns".

**Issue**: Can't decide between Ctrl+I and Ctrl+Shift+I for an edit

- **Quick Fix**: Ask yourself: "Does this change affect multiple files?" If yes, use Ctrl+Shift+I (Edit Mode). If no, use Ctrl+I (inline chat). When in doubt, start with Ctrl+I—you can always escalate to Edit Mode if the inline suggestion indicates multi-file needs.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
