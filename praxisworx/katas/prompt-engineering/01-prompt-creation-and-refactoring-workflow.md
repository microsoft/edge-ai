---
title: 01 - Prompt Creation and Refactoring Workflow
description: Master the end-to-end prompt engineering workflow using prompt-new and prompt-refactor to create, modify, and optimize prompts from source code
author: Edge AI Team
ms.date: 2025-06-17
ms.topic: kata
estimated_reading_time: 8
difficulty: beginner
duration: 30-45 minutes
keywords:
  - praxisworx
  - prompt engineering
  - prompt creation
  - prompt refactoring
  - workflow optimization
  - source code analysis
  - prompt improvement
  - numbered progression
---

## Quick Context

**You'll Learn**: Master the complete prompt engineering workflow from creation to optimization using structured analysis of existing code patterns.

**Real Challenge**: Your team needs to standardize Terraform infrastructure module creation. Analyze existing Terraform patterns in `src/000-cloud/` components and create an agent prompt that generates new modules following the same architectural patterns and organizational conventions.

**Your Task**: Use the prompt-new and prompt-refactor workflow to create a professional agent prompt that analyzes Terraform module structures and generates new modules with proper variables, resources, and outputs following project conventions.

## 🤖 AI Coaching Available - Get Interactive Help

> **🚀 Supercharge Your Learning with AI Coaching**
>
> **New to AI-assisted learning? Want task check-offs, progress tracking, and personalized guidance?**
>
> Load our specialized **PraxisWorx Kata Coach** for:
>
> - ✅ **Task Check-offs**: Mark completed tasks and track your progress
> - 🎯 **Learning Evaluation**: Reflect on your progress with guided questions
> - 🆘 **Coaching & Troubleshooting**: Get progressive hints when you're stuck
> - 🔄 **Session Resumption**: Pick up exactly where you left off
> - 🧭 **Smart Guidance**: Personalized coaching based on your progress patterns

### How to Load Your AI Coach

**Step 1**: In GitHub Copilot Chat, select the **PraxisWorx Kata Coach** mode from the chat mode selector.

**Step 2**: Send this starter message to begin your coached session:

```text
I'm working on Prompt Creation and Refactoring Workflow kata and want interactive coaching with progress tracking and learning evaluation.
```

**💡 Pro Tip**: Your coach can see your checkbox progress when you're using the local docs (`npm run docs:training`) and help you manage it!

### Essential Setup

**Required** (check these first):

- [ ] Completion of AI Development Fundamentals kata
- [ ] Familiarity with project structure and Terraform concepts
- [ ] GitHub Copilot subscription active
- [ ] Access to project source code in `src/000-cloud/` directory

**Quick Validation**: Can navigate to `src/000-cloud/` and identify Terraform module structures.

## Practice Tasks

### Task 1: Terraform Pattern Analysis and Initial Prompt Creation (15 minutes)

**What You'll Do**: Analyze existing Terraform infrastructure patterns and use prompt-new to create a module generation prompt.

**Steps**:

1. **Analyze** Terraform components in `src/000-cloud/` directory
   - [ ] Select 1-2 components with clear Terraform module patterns
   - [ ] Review file structures, variable definitions, resource patterns, outputs
   - [ ] Identify key patterns: naming conventions, organization, tags, documentation
   - **Expected result**: Clear understanding of Terraform patterns to automate

2. **Use** prompt-new workflow for prompt creation
   - [ ] Open GitHub Copilot and use the prompt-new prompt file
   - [ ] Specify your selected Terraform component as `fromPath`
   - [ ] Set `toPath` to `.copilot-tracking/prompts/terraform-module-generator.prompt.md`
   - **Expected result**: Generated agent prompt that captures Terraform infrastructure patterns

3. **Review** generated prompt quality and completeness
   - [ ] Verify it captures variable patterns, resource organization, output specifications
   - [ ] Check for clarity of infrastructure-specific instructions
   - [ ] Document areas for improvement or missing patterns
   - **Success check**: Agent prompt ready for testing with clear Terraform automation capabilities

### Task 2: Strategic Terraform Prompt Enhancement (10 minutes)

**What You'll Do**: Manually improve the generated prompt to address infrastructure pattern gaps and enhance clarity.

**Steps**:

1. **Identify** specific improvement opportunities
   - [ ] Review generated prompt against original Terraform components
   - [ ] Find gaps in variable validation, resource organization, output naming
   - [ ] Note unclear module generation steps or missing error handling
   - **Expected result**: Clear list of targeted improvements needed

2. **Make** focused Terraform-specific enhancements
   - [ ] Add clearer examples of variable validation from source infrastructure
   - [ ] Improve resource organization instructions based on actual patterns
   - [ ] Clarify output naming conventions found in existing modules
   - **Expected result**: Enhanced prompt with better infrastructure automation clarity

3. **Test** your enhanced prompt effectiveness
   - [ ] Use modified prompt to generate a sample infrastructure module
   - [ ] Evaluate if generated code follows project patterns and conventions
   - **Success check**: Generated Terraform code matches existing patterns and quality standards

### Task 3: Systematic Refactoring and Optimization (15 minutes)

**What You'll Do**: Use prompt-refactor to systematically optimize your enhanced prompt for maximum effectiveness.

**Steps**:

1. **Execute** prompt-refactor workflow
   - [ ] Use prompt-refactor prompt file with your modified prompt as input
   - [ ] Leave focus empty for general refactoring or specify "organization"
   - [ ] Follow all steps: analysis, refactoring process, organizational improvements
   - **Expected result**: Systematically refactored prompt with improved structure and clarity

2. **Compare** workflow results and effectiveness
   - [ ] Compare original generated, manually enhanced, and refactored versions
   - [ ] Identify key improvements made during each phase
   - [ ] Assess overall clarity and usability improvements
   - **Expected result**: Clear understanding of each phase's contribution to prompt quality

3. **Document** lessons learned and workflow insights
   - [ ] Record what Terraform patterns were most valuable to capture
   - [ ] Note which manual changes had biggest impact on module generation
   - [ ] Document how refactoring improved the final prompt
   - **Success criteria**: Comprehensive understanding of prompt engineering workflow effectiveness

## Completion Check

**You've Succeeded When**:

- [ ] Created agent prompt that generates Terraform modules following project patterns
- [ ] Successfully enhanced prompt through manual improvements and systematic refactoring
- [ ] Demonstrated complete prompt engineering workflow from analysis to optimization
- [ ] Generated documentation showing workflow effectiveness and lessons learned

## Next Steps

**Continue Learning**: Practice with `02-basic-prompt-structure.md` for advanced prompt design principles

**Apply Skills**: Use this systematic prompt engineering workflow for creating and optimizing prompts in real development work

## Resources

- [Prompts Overview](/.github/prompts/README.md) - Complete guide to available prompts including prompt-new and prompt-refactor workflows
- [Prompt-New Workflow](/.github/prompts/prompt-new.prompt.md) - Systematic prompt creation guidance
- [Prompt-Refactor Workflow](/.github/prompts/prompt-refactor.prompt.md) - Prompt optimization methodology
- [Azure OpenAI Documentation][prompt-engineering-azure] - Prompt engineering principles for best practices

---

<!-- Reference Links -->
[prompt-engineering-azure]: https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/prompt-engineering

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
