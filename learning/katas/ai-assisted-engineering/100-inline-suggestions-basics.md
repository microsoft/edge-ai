---
title: 'Kata: 100 - Inline Suggestions Basics'
description: Learn GitHub Copilot's inline suggestions with Tab acceptance, Alt+] navigation, and comment-driven development for Terraform and Bicep IaC workflows
author: Edge AI Team
ms.date: 2025-01-25
kata_id: ai-assisted-engineering-100-inline-suggestions-basics
kata_category:
  - ai-assisted-engineering
kata_difficulty: 1
estimated_time_minutes: 30
learning_objectives:
  - Accept inline code suggestions using Tab key for rapid Terraform and Bicep development
  - Navigate alternative suggestions with Alt+]/Option+] to find optimal implementations
  - Apply comment-driven development patterns with partial acceptance for complex IaC resources
prerequisite_katas: []
technologies:
  - GitHub Copilot
  - Terraform
  - Bicep
  - Visual Studio Code
success_criteria:
  - Successfully accept and navigate inline suggestions for 5+ Terraform resources
  - Cycle through alternative suggestions to compare implementation options
  - Use comment-driven development with partial acceptance for complex infrastructure code
ai_coaching_level: guided
scaffolding_level: heavy
hint_strategy: progressive
common_pitfalls:
  - Accepting first suggestion without reviewing alternatives or checking against conventions
  - Not using comments to guide Copilot toward specific implementation patterns
  - Forgetting keyboard shortcuts and reverting to mouse-based workflows
  - Accepting suggestions that violate project naming conventions or structure
requires_azure_subscription: false
requires_local_environment: true
tags:
  - ai-assisted-engineering
search_keywords:
  - inline-suggestions
  - tab-completion
  - ghost-text
  - copilot-navigation
  - comment-driven-development
---

## Quick Context

You're working on Terraform components for the edge-ai project and typing `resource "azurerm_` when gray "ghost text" appears suggesting the complete resource block. Press Tab and watch an entire resource definition materialize. This is GitHub Copilot's inline suggestion engine—your most-used productivity multiplier for infrastructure-as-code development.

**Real Challenge**: 80% of IaC development involves typing similar patterns: resource blocks, variable definitions, output declarations. Inline suggestions eliminate repetitive typing and help maintain project conventions automatically. But accepting the first suggestion without review can introduce inconsistencies or miss better alternatives.

**Your Task**: Learn the Tab acceptance workflow, navigate alternatives with Alt+]/Option+], and use comment-driven development to guide Copilot toward project-specific patterns. You'll work with real Terraform examples from edge-ai components.

## Essential Setup

**Required** (check these first):

- [ ] Visual Studio Code with GitHub Copilot extension installed
- [ ] Active GitHub Copilot subscription
- [ ] Repository cloned to `/workspaces/edge-ai`
- [ ] VS Code opened to workspace root (not subdirectory)
- [ ] Copilot icon in status bar shows "Ready"

**Quick Validation**: Open any `.tf` file, type `resource "azurerm_` and wait 1-2 seconds. Gray ghost text should appear. If not, check Copilot status bar icon.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** chat mode for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** mode and say:
>
> ```text
> I'm working on 100 - Inline Suggestions Basics kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Accept Inline Suggestions with Tab Key (10 minutes)

**What You'll Do**: Practice accepting inline suggestions for common Terraform resource patterns, understanding ghost text indicators, and building muscle memory for Tab acceptance.

**Steps**:

1. **Create** a new Terraform file for hands-on practice
   - [ ] Create file: `/workspaces/edge-ai/src/000-cloud/010-security-identity/terraform/practice-inline-suggestions.tf`
   - [ ] Open the file in VS Code
   - [ ] Type the comment: `# Azure Key Vault for secrets management`
   - [ ] Press Enter to move to next line
   - **Pro tip**: Comments guide Copilot's context—specific comments yield better suggestions
   - [ ] **Expected result**: Empty Terraform file ready for inline suggestion practice

2. **Accept** your first inline suggestion for Key Vault resource
   - [ ] Type: `resource "azurerm_key_vault" "main" {`
   - [ ] Wait 1-2 seconds for gray ghost text to appear (shows suggested completion)
   - [ ] Read the suggested content—verify it includes name, location, resource_group_name
   - [ ] Press **Tab** to accept the entire suggestion
   - **Validation checkpoint**: Did the ghost text transform into actual code? Can you see the complete resource block?
   - [ ] **Expected result**: Complete `azurerm_key_vault` resource block with multiple attributes

3. **Practice** Tab acceptance with 4 more common resources
   - [ ] Add comment: `# Managed Identity for workload authentication`
   - [ ] Type: `resource "azurerm_user_assigned_identity"` and press Tab when ghost text appears
   - [ ] Add comment: `# Log Analytics Workspace for centralized logging`
   - [ ] Type: `resource "azurerm_log_analytics_workspace"` and press Tab
   - [ ] Add comment: `# Storage Account for data persistence`
   - [ ] Type: `resource "azurerm_storage_account"` and press Tab
   - [ ] Add comment: `# Container Registry for container images`
   - [ ] Type: `resource "azurerm_container_registry"` and press Tab
   - **Pro tip**: Notice how specific comments before each resource influence suggestion quality
   - **Validation checkpoint**: Do you have 5 complete Terraform resources? Did Tab acceptance feel natural?
   - [ ] **Expected result**: Practice file with 5 distinct Azure resource blocks, all accepted via Tab key

### Task 2: Navigate Alternative Suggestions with Keyboard Shortcuts (10 minutes)

**What You'll Do**: Learn to cycle through alternative suggestions using Alt+]/Option+] to compare implementations and choose the best option for your context.

**Steps**:

1. **Discover** the alternative suggestions navigator
   - [ ] Create new file: `/workspaces/edge-ai/src/000-cloud/010-security-identity/terraform/practice-alternatives.tf`
   - [ ] Type comment: `# Virtual Network with multiple subnets for edge cluster`
   - [ ] Type: `resource "azurerm_virtual_network" "main" {`
   - [ ] When ghost text appears, press **Alt+]** (Windows/Linux) or **Option+]** (Mac) instead of Tab
   - [ ] Press Alt+]/Option+] again to see the next alternative
   - [ ] Press **Alt+[**/Option+[ to go back to previous suggestion
   - **Pro tip**: Copilot generates multiple suggestions—first isn't always best for your conventions
   - **Validation checkpoint**: Can you cycle forward and backward through at least 3 different suggestions?
   - [ ] **Expected result**: Ability to navigate through alternative virtual network implementations

2. **Compare** alternatives for tag standardization patterns
   - [ ] In the `azurerm_virtual_network` resource you're viewing, look at the `tags` block in each alternative
   - [ ] Use Alt+]/Option+] to cycle through at least 3 alternatives
   - [ ] Observe differences: some may have `Environment`, `Project`, `ManagedBy` tags; others may be minimal
   - [ ] Choose the alternative that matches edge-ai conventions (check `/src/000-cloud/010-security-identity/terraform/main.tf` for reference)
   - [ ] Press **Tab** to accept the best alternative
   - **Validation checkpoint**: Did you find an alternative with comprehensive tags matching project standards?
   - [ ] **Expected result**: Accepted virtual network resource with project-standard tags

3. **Practice** alternative navigation with 2 more complex resources
   - [ ] Type comment: `# Network Security Group with restrictive rules`
   - [ ] Type: `resource "azurerm_network_security_group"` and trigger suggestions
   - [ ] Cycle through alternatives with Alt+]/Option+] looking for one with multiple security rules defined
   - [ ] Accept the most comprehensive alternative with Tab
   - [ ] Type comment: `# Azure Container Registry with geo-replication`
   - [ ] Type: `resource "azurerm_container_registry"` and trigger suggestions
   - [ ] Cycle through alternatives looking for one with `georeplications` block
   - [ ] Accept the alternative that shows advanced configuration
   - **Pro tip**: Alternative navigation lets you discover Copilot's knowledge of advanced resource configurations
   - **Success check**: Can you confidently navigate alternatives and explain why you chose specific suggestions?
   - [ ] **Expected result**: Two complex resources selected from alternatives based on feature completeness

### Task 3: Comment-Driven Development with Partial Acceptance (10 minutes)

**What You'll Do**: Use detailed comments to guide Copilot toward specific implementations, then use partial acceptance (Ctrl+→/Cmd+→) for complex multi-line suggestions.

**Steps**:

1. **Guide** Copilot with descriptive comments for complex component
   - [ ] Create file: `/workspaces/edge-ai/src/000-cloud/070-kubernetes/terraform/practice-comment-driven.tf`
   - [ ] Type detailed comment:

     ```hcl
     # Azure Kubernetes Service cluster with:
     # - System node pool with 2 nodes
     # - User node pool with autoscaling 1-5 nodes
     # - Azure CNI networking
     # - Managed identity authentication
     # - Azure Policy and monitoring enabled
     ```

   - [ ] Type: `resource "azurerm_kubernetes_cluster" "main" {`
   - [ ] Wait for inline suggestion to appear
   - **Pro tip**: Detailed comments with bullet points guide Copilot to generate exactly what you need
   - **Validation checkpoint**: Does the ghost text suggestion include system_node_pool, default_node_pool, network_profile, and identity blocks?
   - [ ] **Expected result**: Comprehensive AKS resource suggestion matching your detailed requirements

2. **Practice** partial acceptance for long suggestions
   - [ ] Review the ghost text suggestion line by line without accepting yet
   - [ ] Press **Ctrl+→** (Windows/Linux) or **Cmd+→** (Mac) to accept only the current word
   - [ ] Continue pressing Ctrl+→/Cmd+→ to accept word-by-word, observing each addition
   - [ ] When you reach the end of a logical block (e.g., `name` attribute), press **Enter** to accept the line and move to next
   - [ ] Continue until you've accepted the entire `azurerm_kubernetes_cluster` resource
   - **Pro tip**: Partial acceptance gives you control over complex suggestions, letting you verify each section
   - **Validation checkpoint**: Did partial acceptance help you understand the resource structure better than Tab-accepting everything?
   - [ ] **Expected result**: Complete AKS resource accepted incrementally with full understanding of each section

3. **Apply** comment-driven development to lifecycle management
   - [ ] Type detailed comment:

     ```hcl
     # Data source referencing existing resource group
     # Used for dependency management without creating new RG
     ```

   - [ ] Type: `data "azurerm_resource_group" "existing" {`
   - [ ] Accept suggestion with Tab
   - [ ] Type detailed comment:

     ```hcl
     # Null resource with lifecycle rules:
     # - Ignore changes to tags
     # - Prevent destruction
     # - Create before destroy pattern
     ```

   - [ ] Type: `resource "null_resource" "example" {`
   - [ ] Wait for suggestion, then navigate alternatives with Alt+]/Option+] to find one with `lifecycle` block
   - [ ] Accept the alternative that includes comprehensive lifecycle rules
   - **Pro tip**: Comment-driven development is especially powerful for lifecycle rules, provisioners, and complex nested blocks
   - **Success check**: Do your comments now guide Copilot to generate exactly what you need without manual editing?
   - [ ] **Expected result**: Data source and null resource with lifecycle blocks, all generated from descriptive comments

## Completion Check

**You've Succeeded When**:

- [ ] Accepted inline suggestions with Tab for 5+ Terraform resources without mouse interaction
- [ ] Navigated alternatives with Alt+]/Option+] and can explain differences between suggestions
- [ ] Used comment-driven development to generate complex resources matching project patterns
- [ ] Applied partial acceptance with Ctrl+→/Cmd+→ for multi-line suggestions
- [ ] Can confidently choose between accepting first suggestion vs. exploring alternatives

**Test your understanding** (try without looking at notes):

- [ ] **Keyboard shortcuts**: List the 3 main inline suggestion shortcuts (Tab, Alt+], Ctrl+→)
- [ ] **When to navigate**: Explain when you'd press Alt+] instead of Tab
- [ ] **Comment impact**: Describe how comment specificity affects suggestion quality
- [ ] **Partial acceptance**: When would you use Ctrl+→ instead of Tab?

**Confidence check**:

- [ ] I can accept inline suggestions faster than typing manually
- [ ] I know when to cycle through alternatives vs. accepting first suggestion
- [ ] I can write comments that guide Copilot to project-specific patterns

**Next Steps**: Continue to **100 - Inline Chat Quick Edits** to learn Ctrl+I for selection-based modifications and refactoring.

---

## Reference Appendix

### Help Resources

**Core Resources**:

- [GitHub Copilot Documentation](https://docs.github.com/en/copilot) - Official keyboard shortcuts and features
- [VS Code Keyboard Shortcuts](https://code.visualstudio.com/docs/getstarted/keybindings) - Full shortcut reference
- [Terraform Resource Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) - Azure resource reference

**Project Resources**:

- Component Structure: `src/README.md` - Component organization patterns
- Terraform Conventions: `.github/instructions/terraform.instructions.md` - Project Terraform standards

### Professional Tips

- Accept first suggestion for simple, repetitive code; navigate alternatives for complex or convention-sensitive code
- Use specific comments as "prompts" before resource blocks—Copilot reads surrounding context within ~10 lines
- Keyboard shortcuts are faster than mouse—build muscle memory for Tab, Alt+], and Ctrl+→
- When suggestions don't match project conventions, improve your comments rather than accepting and editing manually
- Partial acceptance (Ctrl+→) is excellent for learning new Terraform resource structures

### Troubleshooting

**Issue**: No ghost text appears after typing

- **Quick Fix**: Check Copilot status bar icon. If inactive, click it and ensure subscription is active. Verify file is saved with `.tf` extension for Terraform language detection.

**Issue**: Suggestions don't match project conventions

- **Quick Fix**: Add more specific comments describing expected patterns. Reference existing files in your comment (e.g., `# Similar to main.tf in 010-security-identity`). Open related files in editor tabs—Copilot reads open files for context.

**Issue**: Alt+] doesn't cycle through alternatives

- **Quick Fix**: Ensure suggestion is active (gray ghost text visible). On Windows, check that Alt key isn't captured by another application. On Mac, verify Option+] isn't mapped to another command in VS Code keyboard shortcuts.

**Issue**: Accepted suggestion breaks Terraform validation

- **Quick Fix**: Run `terraform validate` to see specific errors. Use inline chat (Ctrl+I) to fix validation issues. Review `.github/instructions/terraform.instructions.md` for project standards, then improve guiding comments.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
