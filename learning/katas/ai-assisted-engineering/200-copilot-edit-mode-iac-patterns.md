---
title: 'Kata: 200 - GitHub Copilot Edit Chat Mode for IaC Patterns'
description: Apply GitHub Copilot Edit chat mode to Infrastructure as Code workflows including Terraform variable consistency, Bicep type coordination, and Terraform resource tagging using @workspace context, #-file mentions, and git restore workflow
author: Edge AI Team
ms.date: 2025-01-24
kata_id: ai-assisted-engineering-200-copilot-edit-mode-iac-patterns
kata_category:
  - ai-assisted-engineering
kata_difficulty: 2
estimated_time_minutes: 60
learning_objectives:
  - Apply Edit chat mode to Terraform variable consistency patterns using @workspace context on real repository files
  - Coordinate Bicep type definitions across modules with #-file mentions
  - Practice safe, reversible infrastructure changes with git restore workflow
  - Choose appropriate chat context mechanism (@workspace vs #-mentions) for IaC workflows
prerequisite_katas:
  - ai-assisted-engineering-200-copilot-edit-mode-basics
technologies:
  - GitHub Copilot
  - GitHub Copilot Chat
  - Chat Edit Mode
  - Terraform
  - Bicep
  - Git
success_criteria:
  - Successfully apply Terraform variable descriptions/validation across 4+ component files using Edit chat mode
  - Coordinate Bicep type changes across modules using @workspace or #-mentions
  - Add standardized tags to Terraform resources across multiple components using Edit chat mode
  - Demonstrate safe practice workflow with git status and git restore
  - Demonstrate informed choice between @workspace context and #-file mentions for IaC tasks
ai_coaching_level: guided
scaffolding_level: medium-heavy
hint_strategy: progressive
common_pitfalls:
  - "Not providing enough context with @workspace - Edit chat mode needs clear scope for file discovery"
  - "Using #-mentions for many files when @workspace would be more efficient"
  - "Not validating IaC syntax after multi-file edits - always run validate/lint commands"
  - "Forgetting to run git status and git restore after practice changes"
  - "Accepting changes to real infrastructure files without reviewing diffs carefully"
requires_azure_subscription: false
requires_local_environment: true
tags:
  - ai-assisted-engineering
search_keywords:
  - copilot edit chat mode iac
  - chat mode selector
  - workspace context iac
  - terraform multi-file
  - bicep type coordination
  - git restore workflow
  - infrastructure consistency
  - safe iac practice
---

## Quick Context

**You'll Learn**: Apply GitHub Copilot Edit chat mode to Infrastructure as Code (IaC) workflows including Terraform variable consistency, Bicep type coordination, and resource tagging using @workspace context and #-file mentions on real repository infrastructure files with git restore workflow for safe practice.

**Prerequisites**: Completion of Edit Mode Basics kata (ai-assisted-engineering-200-copilot-edit-mode-basics), familiarity with Terraform and Bicep, VS Code with GitHub Copilot extension

**Real Challenge**: Your infrastructure team needs to add consistent variable descriptions and validation across multiple Terraform components in src/000-cloud/, coordinate Bicep type definitions in the messaging component, and add standardized resource tags to Azure resources. Manual updates risk inconsistency and errors. This kata teaches you to use Edit chat mode with @workspace discovery for systematic IaC coordination on real repository files, then safely reset changes with git restore.

**Your Task**: Practice Edit chat mode with infrastructure patterns using @workspace and #-mentions to build fluency with Terraform and Bicep multi-file workflows on real infrastructure code, using git restore to safely reset your practice changes.

## Essential Setup

**Required** (check these first):

- [ ] Completed kata 200-copilot-edit-mode-basics (prerequisite for multi-file IaC patterns)
- [ ] VS Code with GitHub Copilot extension active
- [ ] GitHub Copilot Chat panel accessible (Ctrl+Alt+I / Cmd+Alt+I)
- [ ] Chat mode selector visible in Chat panel (can switch between Ask/Edit/Plan/Agent modes)
- [ ] Understanding of @workspace context for broad file discovery
- [ ] Familiarity with #-file mentions for specific file targeting
- [ ] Terraform CLI installed (1.5+) or Azure CLI with Bicep (0.20+) or kubectl (1.28+)
- [ ] Understanding of modules/manifests for chosen IaC technology
- [ ] Familiarity with validation workflows (terraform validate, az bicep build, or kubectl apply --dry-run)
- [ ] Time allocated: 60 minutes for Terraform, Bicep, and Kubernetes multi-file coordination practice

**Quick Validation**: Verify you can run `terraform --version`, `az bicep version`, `kubectl version --client`, and open Chat panel (Ctrl+Alt+I) with visible mode selector dropdown to switch to Edit mode.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** chat mode for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** mode and say:
>
> ```text
> I'm working on GitHub Copilot Edit Mode for IaC Patterns kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Terraform Variable Consistency (20 minutes)

**What You'll Do**: Apply Edit chat mode to add variable descriptions and validation blocks across real Terraform components in src/000-cloud/ using @workspace context, then safely reset changes with git restore

<!-- AI_COACH: Terraform variable consistency requires understanding component boundaries and variable patterns. If learners struggle with providing context, guide them to use @workspace with clear directory scopes (e.g., '@workspace In src/000-cloud/'). Remind them this is practice on real infrastructure files with safe, reversible changes. Emphasize git status and git restore for cleanup. -->

**Steps**:

1. **Understand** Terraform variable patterns and safe practice
   - [ ] **Variable consistency**: Adding descriptions and validation to variables across components
   - [ ] **Safe changes**: Descriptions and validation blocks are non-breaking additions
   - [ ] **Edit chat mode advantage**: @workspace discovers related variables.tf files, consistent syntax across all changes
   - [ ] **Context strategies**: Use @workspace for broad discovery, #-mentions for specific files
   - [ ] **Git restore workflow**: Check git status before, make changes, then git restore to reset
   - [ ] **Expected result**: Understanding of safe Terraform practice with git-reversible changes

2. **Explore** existing Terraform components and check git status
   - [ ] Run `git status` in terminal to verify clean working directory
   - [ ] Navigate to `src/000-cloud/` directory in VS Code explorer
   - [ ] Examine `010-security-identity/terraform/variables.tf`
   - [ ] Note which variables have descriptions and which don't
   - [ ] Check `020-observability/terraform/variables.tf` and `030-data/terraform/variables.tf`
   - [ ] **Expected result**: Familiarity with real Terraform variable patterns in this project

3. **Activate** Edit chat mode
   - [ ] Open GitHub Copilot Chat panel (Ctrl+Alt+I / Cmd+Alt+I)
   - [ ] Click the mode selector dropdown at the top of the Chat panel
   - [ ] Select "Edit" from the dropdown (Ask / Edit / Plan / Agent)
   - [ ] Verify "Edit" mode is active in the chat panel
   - [ ] **Expected result**: Edit chat mode active and ready for multi-file coordination

4. **Request** variable description additions with @workspace
   - [ ] **Prompt**: `@workspace In src/000-cloud/ find all variables.tf files. Add helpful descriptions to any variables that are missing them, explaining their purpose in the infrastructure component.`
   - [ ] Wait for Edit chat mode to analyze files and propose changes
   - [ ] Review the diff previews ensuring descriptions are clear and accurate
   - [ ] **Pro tip**: Edit mode should add descriptions to undocumented variables across multiple components
   - [ ] Accept the suggested changes to apply them
   - [ ] **Expected result**: Variables in security-identity, observability, and data components now have descriptions

5. **Request** validation blocks with #-file mentions
   - [ ] **Prompt**: `#src/000-cloud/010-security-identity/terraform/variables.tf #src/000-cloud/020-observability/terraform/variables.tf Add a validation block to the 'environment' variable requiring it to be one of: dev, test, prod`
   - [ ] Review the validation block syntax in diff previews
   - [ ] Verify condition and error_message are appropriate
   - [ ] Accept the changes
   - [ ] **Expected result**: Environment variables in two components now have validation constraints

6. **Practice** rejection workflow with location change
   - [ ] **Prompt**: `@workspace In src/000-cloud/ change all 'location' variable default values to 'westus3'`
   - [ ] **Important**: Review the proposed changes carefully
   - [ ] **Reject** the changes by clicking "Dismiss" or "Cancel" in the chat interface
   - [ ] **Pro tip**: This demonstrates Edit chat mode's ability to propose changes you can safely reject
   - [ ] Verify no files were modified by checking git status
   - [ ] **Expected result**: No changes applied - rejection workflow practiced successfully

7. **Clean up** with git restore
   - [ ] Run `git status` in terminal to see which variables.tf files were modified
   - [ ] Run `git restore src/000-cloud/*/terraform/variables.tf` to reset all practice changes
   - [ ] Run `git status` again to verify clean working directory
   - [ ] **Pro tip**: This git restore workflow lets you practice on real infrastructure safely
   - [ ] **Expected result**: All Terraform variable files restored to original state, clean git status

### Task 2: Bicep Type Coordination (20 minutes)

**What You'll Do**: Add optional properties and @description decorators to real Bicep type definitions in src/000-cloud/040-messaging/bicep/types.bicep using Edit chat mode, then safely reset with git restore

<!-- AI_COACH: Bicep type coordination requires understanding type definitions and safe, backward-compatible changes. Guide learners to add optional properties (using ? syntax) and @description decorators - both are non-breaking changes. Emphasize git restore for cleanup after practice. -->

**Steps**:

1. **Understand** Bicep type patterns and safe changes
   - [ ] **Shared types**: Type definitions used across Bicep modules in components
   - [ ] **Safe additions**: Optional properties (tags?, metadata?) and @description decorators are non-breaking
   - [ ] **Edit chat mode strategy**: Use @workspace for discovering types.bicep files, #-file for specific targeting
   - [ ] **Git restore workflow**: Check git status before, make changes, then git restore to reset
   - [ ] **Expected result**: Understanding of safe Bicep type practice with git-reversible changes

2. **Explore** existing Bicep types and check git status
   - [ ] Run `git status` to verify clean working directory
   - [ ] Navigate to `src/000-cloud/040-messaging/bicep/types.bicep`
   - [ ] Examine existing type definitions (look for Common, MessagingConfig, or similar types)
   - [ ] Note which properties exist and which descriptions are present
   - [ ] Check if other components have types.bicep files with @workspace search
   - [ ] **Expected result**: Familiarity with real Bicep type patterns in messaging component

3. **Activate** Edit chat mode
   - [ ] Ensure Edit chat mode is active (or reactivate via mode selector)
   - [ ] **Expected result**: Edit chat mode ready for Bicep type coordination

4. **Request** optional property additions with #-file
   - [ ] **Prompt**: `#src/000-cloud/040-messaging/bicep/types.bicep Add an optional 'tags' property (tags: object?) to the main configuration type definition if it doesn't already have one.`
   - [ ] Wait for Edit chat mode to propose changes
   - [ ] Review the diff ensuring the optional syntax (?) is used correctly
   - [ ] Accept the changes
   - [ ] **Expected result**: Type definition now includes optional tags property

5. **Request** @description decorators with @workspace
   - [ ] **Prompt**: `@workspace In src/000-cloud/040-messaging/bicep/types.bicep add @description decorators to any type properties that are missing them, explaining their purpose.`
   - [ ] Review proposed @description additions
   - [ ] Verify descriptions are clear and accurate for messaging infrastructure
   - [ ] Accept the changes
   - [ ] **Pro tip**: @description decorators improve IntelliSense and documentation without breaking changes
   - [ ] **Expected result**: Type properties now have helpful @description decorators

6. **Validate** Bicep changes
   - [ ] Run `az bicep build --file src/000-cloud/040-messaging/bicep/main.bicep` to test compilation
   - [ ] Verify no type errors or compilation issues
   - [ ] **Expected result**: Successful Bicep build with enhanced type documentation

7. **Clean up** with git restore
   - [ ] Run `git status` to see types.bicep modifications
   - [ ] Run `git restore src/000-cloud/040-messaging/bicep/types.bicep` to reset changes
   - [ ] Run `git status` again to verify clean working directory
   - [ ] **Expected result**: Bicep type file restored to original state, safe practice complete

### Task 3: Kubernetes Manifest Consistency (20 minutes)

**What You'll Do**: Maintain Kubernetes label and annotation consistency across multiple manifests with Edit chat mode

<!-- AI_COACH: Kubernetes manifest consistency is crucial for resource management and observability. When learners work with labels and annotations, encourage them to think about: Which resources need consistent labeling? What's the label schema? How do selectors depend on labels? For Edit chat mode, @workspace works well when all manifests are in one directory. -->

**Steps**:

1. **Understand** Kubernetes consistency patterns
   - [ ] **Label consistency**: Standard labels across all resources for organization and selection
   - [ ] **Annotation patterns**: Metadata for tools (Prometheus, ingress controllers)
   - [ ] **Common scenarios**: Add version label, update app labels, standardize annotations
   - [ ] **Azure resource tagging**: Tags enable cost tracking, governance, and environment identification
   - [ ] **Safe additions**: Tags don't break existing resources and can be reset with git restore
   - [ ] **Expected result**: Understanding of Azure tagging patterns and git restore workflow

2. **Explore** Terraform resources in `src/000-cloud/`
   - [ ] Navigate to `src/000-cloud/010-security-identity/terraform/main.tf` in the Editor
   - [ ] Examine the `azurerm_*` resource blocks and observe existing tags blocks (if any)
   - [ ] Navigate to `src/000-cloud/020-observability/terraform/main.tf` and `src/000-cloud/030-data/terraform/main.tf`
   - [ ] **Git safety checkpoint**: Run `git status` in the terminal to verify working directory is clean
   - [ ] **Expected result**: Familiarity with Azure resource structure before adding tags

3. **Activate** Edit chat mode
   - [ ] Click mode selector dropdown in Chat panel
   - [ ] Select **Edit** mode
   - [ ] **Expected result**: Edit mode active (see mode indicator in Chat panel)

4. **Add** Environment tag to security-identity component
   - [ ] **Prompt with @workspace**: `@workspace In src/000-cloud/010-security-identity/terraform/main.tf find all azurerm resource blocks and add a 'tags' block with an 'Environment' tag set to 'dev'. Only modify resources that don't already have Environment tags.`
   - [ ] Wait for Edit chat mode to propose changes to main.tf
   - [ ] **Review carefully**: Are tags being added correctly to azurerm resource blocks?
   - [ ] **Pro tip**: Some resources may already have tags; Edit mode should preserve existing tags
   - [ ] Accept the changes to apply them to main.tf
   - [ ] **Expected result**: azurerm resources in security-identity gain Environment = "dev" tag

5. **Add** ManagedBy and Project tags across multiple components
   - [ ] Stay in Edit chat mode (same session)
   - [ ] **Prompt with @workspace**: `@workspace In src/000-cloud/ add standardized tags to all azurerm resource blocks in the main.tf files: add 'ManagedBy = "Terraform"' and 'Project = "EdgeAI"' to the tags block. Preserve any existing tags.`
   - [ ] Wait for Edit chat mode to discover and propose changes across multiple components
   - [ ] Review diffs carefully in the chat panel (may include security-identity, observability, data components)
   - [ ] **Validation checkpoint**: Are tags being merged with existing tags (not replacing them)?
   - [ ] Accept the changes to apply them across all discovered main.tf files
   - [ ] **Expected result**: Consistent ManagedBy and Project tags across multiple components

6. **Validate** Terraform formatting and syntax
   - [ ] Run `terraform fmt -recursive` in the terminal from `src/000-cloud/` directory
   - [ ] Navigate to any modified component (e.g., `src/000-cloud/010-security-identity/terraform/`)
   - [ ] Run `terraform validate` to check for syntax errors
   - [ ] Repeat validation for other modified components
   - [ ] **Expected result**: All Terraform files formatted correctly and pass validation

7. **Git restore** to reset practice changes
   - [ ] Run `git status` in terminal to see all modified main.tf files
   - [ ] Run `git restore src/000-cloud/*/terraform/main.tf` to reset all Terraform main files
   - [ ] Run `git status` again to verify clean working directory
   - [ ] **Success check**: All practice changes undone, infrastructure code restored to original state, comfortable with real-file practice using git restore

## Completion Check

**You've Succeeded When**:

- [ ] You added variable descriptions and validation blocks across 4+ Terraform components using Edit chat mode with @workspace context
- [ ] You coordinated Bicep type definition changes in real src/000-cloud/040-messaging/bicep/types.bicep using #-file mentions
- [ ] You applied standardized Azure resource tags across multiple components using Edit chat mode with @workspace
- [ ] You can articulate when to use @workspace vs. #-mentions for different IaC workflows
- [ ] You understand how to switch to Edit chat mode via the mode selector dropdown
- [ ] You validated all IaC changes with appropriate tools (terraform fmt, terraform validate, az bicep build)
- [ ] You successfully used git restore to reset all practice changes on real infrastructure files
- [ ] You can explain the difference between Edit chat mode (this kata) and Ask chat mode for IaC tasks

**Next Steps**: [300 - Getting Started Advanced][kata-300] — Apply patterns to large-scale architecture

---

## Reference Appendix

### Help Resources

- [Learning Kata Coach][kata-coach] — Your AI assistant for guided kata completion and troubleshooting
- [Terraform Documentation][terraform-docs] — Variable validation and resource tagging reference
- [Bicep Type System][bicep-types] — Type definitions and parameter handling
- [Azure Resource Tagging][azure-tags] — Best practices for Azure resource tags

### Professional Tips

- **Terraform**: Always run `terraform fmt` and `terraform validate` after making changes to infrastructure files
- **Bicep**: Use `az bicep build` to validate type definitions and module interfaces before deployment
- **Git workflow**: Always check `git status` before and after practice changes; use `git restore` to reset real infrastructure files
- **Context strategy**: Use @workspace for directory-wide IaC changes (e.g., all components in src/000-cloud/), #-mentions for specific files
- **Chat mode switching**: Use mode selector dropdown to switch between Ask mode (understanding) and Edit mode (making changes)
- **Validation workflow**: Edit chat mode → Review diffs in chat → Accept changes → Validate (terraform validate, az bicep build) → git restore
- **Real file practice**: Using real repository files with git restore provides authentic experience with zero deployment risk

### Troubleshooting

**Q: I accidentally committed practice changes to real infrastructure files**
**A**: Use `git reset HEAD~1` to undo the commit (keeps changes in working directory), then `git restore` to discard changes. Always verify `git status` is clean before starting practice.

**Q: Bicep build shows type mismatch after Edit Mode changes**
**A**: Verify optional properties use `?` syntax. Check that all consuming modules are updated if type is required. Use `az bicep build --file main.bicep` to validate.

**Q: Terraform validate fails after adding tags**
**A**: Ensure tags block syntax is correct (tags = { ... }). Some Azure resources don't support tags; check provider documentation. Run `terraform fmt` first to fix formatting.

**Q: Should I use Edit chat mode for Terraform refactoring or terraform state commands?**
**A**: Use Edit chat mode for file content changes. Use `terraform state` commands for state manipulation. Never mix the two.

**Q: Edit chat mode can't find my IaC files when I use @workspace**
**A**: Be more specific with directory scope: `@workspace In src/000-cloud/010-security-identity/terraform/`. Or use #-mentions to explicitly target files.

**Q: When should I use @workspace vs. #-mentions for IaC?**
**A**: Use @workspace when you want Edit chat mode to discover related files in a directory (e.g., all variables.tf files). Use #-mentions when you know exactly which files need changes and want explicit control.

**Q: What if git restore doesn't work after practice changes?**
**A**: Use `git status` to see what's changed. If files are staged, use `git restore --staged [file]` first, then `git restore [file]`. Use `git diff [file]` to review changes before restoring.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->

[kata-coach]: /.github/chatmodes/learning-kata-coach.chatmode.md
[terraform-docs]: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
[bicep-types]: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/user-defined-data-types
[azure-tags]: https://learn.microsoft.com/azure/azure-resource-manager/management/tag-resources
[kata-300]: /learning/katas/ai-assisted-engineering/300-getting-started-advanced.md
