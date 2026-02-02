---
title: 'Kata: 300 - Prompt Creation and Refactoring Workflow'
description: Learn systematic prompt creation and refactoring workflows for Edge AI development scenarios
author: Edge AI Team
ms.date: 2025-01-20
kata_id: prompt-engineering-300-prompt-creation-and-refactoring-workflow
kata_category:
  - prompt-engineering
kata_difficulty: 3
estimated_time_minutes: 120
learning_objectives:
  - Learn systematic prompt creation and refactoring workflows
  - Develop effective prompt testing and validation techniques
  - Create reusable prompt patterns for Edge AI scenarios
  - Implement prompt optimization and quality assurance processes
prerequisite_katas: []
technologies:
  - GitHub Copilot
  - Terraform
success_criteria:
  - Create effective prompts using systematic workflow
  - Demonstrate prompt refactoring and optimization
  - Validate prompt quality through testing
  - Develop reusable prompt patterns for infrastructure automation
ai_coaching_level: guided
scaffolding_level: medium
hint_strategy: progressive
common_pitfalls:
  - Creating overly specific prompts that don't generalize to new scenarios
  - Not testing prompts with diverse input scenarios and edge cases
  - Failing to iterate on prompt effectiveness based on output quality
requires_azure_subscription: false
requires_local_environment: true
tags:
  - prompt-engineering
search_keywords:
  - prompt-creation-workflow
  - prompt-refactoring
  - prompt-testing
  - reusable-prompt-patterns
  - prompt-quality-assurance
---

## Quick Context

**You'll Learn**: Develop the complete prompt engineering workflow from creation to optimization using structured analysis of existing code patterns.

**Prerequisites**: VS Code with GitHub Copilot Chat, basic understanding of prompts and instructions, familiarity with Terraform concepts

**Real Challenge**: Your team needs to standardize Terraform infrastructure module creation. Analyze existing Terraform patterns in `src/000-cloud/` components and create an agent prompt that generates new modules following the same architectural patterns and organizational conventions.

**Your Task**: Use the prompt-new and prompt-refactor workflow to create a professional agent prompt that analyzes Terraform module structures and generates new modules with proper variables, resources, and outputs following project conventions.

**💡 Pro Tip**: Your coach can see your checkbox progress when you're using the local docs (`npm run docs`) and help you manage it! Navigate to the Learning section to access all learning resources.

## Essential Setup

Complete these prerequisite checks to ensure a successful learning experience:

**Required** (check these first):

- [ ] Completion of AI Development Fundamentals kata
- [ ] Familiarity with project structure and Terraform concepts
- [ ] GitHub Copilot subscription active
- [ ] Access to project source code in `src/000-cloud/` directory

**Quick Validation**: Verify you can navigate to `src/000-cloud/` and access Terraform module files with GitHub Copilot Chat enabled.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on 01 - Prompt Creation and Refactoring Workflow kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Terraform Pattern Analysis and Initial Prompt Creation (15 minutes)

**What You'll Do**: Analyze existing Terraform infrastructure patterns and use prompt-new to create a module generation prompt.

**Steps**:

1. **Analyze** Terraform components in `src/000-cloud/` directory
   - [ ] Select 1-2 components with clear Terraform module patterns
   - [ ] Review file structures, variable definitions, resource patterns, outputs
   - [ ] Identify key patterns: naming conventions, organization, tags, documentation
   - [ ] **Expected result**: Clear understanding of Terraform patterns to automate

2. **Use** prompt-new workflow for prompt creation
   - [ ] Open GitHub Copilot and use the prompt-new prompt file
   - [ ] Specify your selected Terraform component as `fromPath`
   - [ ] Set `toPath` to `.copilot-tracking/prompts/terraform-module-generator.prompt.md`
   - [ ] **Expected result**: Generated agent prompt that captures Terraform infrastructure patterns

3. **Review** generated prompt quality and completeness
   - [ ] Verify it captures variable patterns, resource organization, output specifications
   - [ ] Check for clarity of infrastructure-specific instructions
   - [ ] Document areas for improvement or missing patterns
   - [ ] **Success check**: Agent prompt ready for testing with clear Terraform automation capabilities

### Task 2: Strategic Terraform Prompt Enhancement (10 minutes)

**What You'll Do**: Manually improve the generated prompt to address infrastructure pattern gaps and enhance clarity.

**Steps**:

1. **Identify** specific improvement opportunities
   - [ ] Review generated prompt against original Terraform components
   - [ ] Find gaps in variable validation, resource organization, output naming
   - [ ] Note unclear module generation steps or missing error handling
   - [ ] **Expected result**: Clear list of targeted improvements needed

2. **Make** focused Terraform-specific enhancements
   - [ ] Add clearer examples of variable validation from source infrastructure
   - [ ] Improve resource organization instructions based on actual patterns
   - [ ] Clarify output naming conventions found in existing modules
   - [ ] **Expected result**: Enhanced prompt with better infrastructure automation clarity

3. **Test** your enhanced prompt effectiveness
   - [ ] Use modified prompt to generate a sample infrastructure module
   - [ ] Evaluate if generated code follows project patterns and conventions
   - [ ] **Success check**: Generated Terraform code matches existing patterns and quality standards

### Task 3: Systematic Refactoring and Optimization (15 minutes)

**What You'll Do**: Use prompt-refactor to systematically optimize your enhanced prompt for maximum effectiveness.

**Steps**:

1. **Execute** prompt-refactor workflow
   - [ ] Use prompt-refactor prompt file with your modified prompt as input
   - [ ] Leave focus empty for general refactoring or specify "organization"
   - [ ] Follow all steps: analysis, refactoring process, organizational improvements
   - [ ] **Expected result**: Systematically refactored prompt with improved structure and clarity

2. **Compare** workflow results and effectiveness
   - [ ] Compare original generated, manually enhanced, and refactored versions
   - [ ] Identify key improvements made during each phase
   - [ ] Assess overall clarity and usability improvements
   - [ ] **Expected result**: Clear understanding of each phase's contribution to prompt quality

3. **Document** lessons learned and workflow insights
   - [ ] Record what Terraform patterns were most valuable to capture
   - [ ] Note which manual changes had biggest impact on module generation
   - [ ] Document how refactoring improved the final prompt
   - [ ] **Success criteria**: Comprehensive understanding of prompt engineering workflow effectiveness

## Completion Check

**You've Succeeded When**:

- [ ] Created agent prompt that generates Terraform modules following project patterns
- [ ] Successfully enhanced prompt through manual improvements and systematic refactoring
- [ ] Demonstrated complete prompt engineering workflow from analysis to optimization
- [ ] Generated documentation showing workflow effectiveness and lessons learned

---

## Reference Appendix

### Help Resources

- [Prompts Overview](../../.github/prompts/README.md) - Complete guide to available prompts including prompt-new and prompt-refactor workflows
- [Prompt-New Workflow](../../.github/prompts/prompt-new.prompt.md) - Systematic prompt creation guidance
- [Prompt-Refactor Workflow](../../.github/prompts/prompt-refactor.prompt.md) - Prompt optimization methodology
- [Azure OpenAI Documentation][prompt-engineering-azure] - Prompt engineering principles for best practices

### Professional Tips

- Start with clear objectives before creating prompts - unclear goals lead to ineffective prompts
- Use prompt-new workflow for new prompts to ensure systematic approach and consistent quality
- Apply prompt-refactor to existing prompts regularly to identify improvement opportunities
- Test prompts with realistic scenarios before production use to validate effectiveness
- Document prompt evolution to capture lessons learned for future improvements

### Troubleshooting

**Prompt generates inconsistent outputs**:

- Review prompt structure for ambiguity or missing context
- Add explicit examples or constraints to guide behavior
- Use prompt-refactor workflow to systematically analyze and improve

**Prompt-new workflow feels overwhelming**:

- Start with minimal required sections (objective, context, constraints)
- Expand prompt iteratively based on output quality
- Reference existing prompts in /.github/prompts/ as templates

**Refactored prompt performs worse than original**:

- Compare outputs side-by-side with test cases to identify regressions
- Roll back changes and apply improvements incrementally
- Validate each change individually to isolate problematic modifications

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
[prompt-engineering-azure]: https://learn.microsoft.com/azure/ai-services/openai/concepts/prompt-engineering
