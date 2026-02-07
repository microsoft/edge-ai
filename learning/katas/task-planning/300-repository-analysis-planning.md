---
title: 'Kata: 300 - Repository Analysis Planning'
description: Develop systematic task planning for repository analysis scripting through component tagging and classification workflows
author: Edge AI Team
ms.date: 2025-06-18
kata_id: task-planning-300-repository-analysis-planning
kata_category:
  - task-planning
kata_difficulty: 3
estimated_time_minutes: 90
learning_objectives:
  - Become proficient in comprehensive repository analysis techniques
  - Develop systematic code and architecture assessment skills
  - Create effective repository evaluation and planning workflows
prerequisite_katas:
  - task-planning-100-edge-documentation-planning
technologies:
  - GitHub Copilot
success_criteria:
  - Complete comprehensive repository analysis
  - Develop systematic assessment methodology
  - Create actionable implementation plans
  - Effective task dependency identification
ai_coaching_level: guided
scaffolding_level: medium
hint_strategy: progressive
common_pitfalls: []
requires_azure_subscription: false
requires_local_environment: true
tags:
  - task-planning
search_keywords:
  - repository-analysis
  - code-assessment
  - systematic-evaluation
  - architecture-review
  - component-tagging
---

## Quick Context

**You'll Learn**: Systematic task planning for repository analysis scripting through component discovery, classification, and automated reporting workflows.

**Prerequisites**: Completion of Edge Documentation Planning kata (task-planning-01), VS Code with GitHub Copilot, access to project workspace with ability to explore repository structure.

**Real Challenge**: Teams need automated ways to analyze complex repositories with multiple components across different directories. Manual analysis is time-consuming and error-prone. You need systematic approaches for building scripts that discover, classify, and report on repository structure.

**Your Task**: Develop a comprehensive task plan for building repository analysis scripts that automatically discover components, classify them by framework and purpose, and generate actionable reports.

**💡 Pro Tip**: Your coach can see your checkbox progress when you're using the local docs (`npm run docs`) and help you manage it! Navigate to the Learning section to access all learning resources.

## Essential Setup

Complete these prerequisite checks to ensure a successful learning experience:

**Required** (check these first):

- [ ] Completion of Edge Documentation Planning kata (01) for methodology foundation
- [ ] VS Code with GitHub Copilot extension active and chat functionality enabled
- [ ] Access to project workspace with ability to explore repository structure
- [ ] Basic understanding of file system navigation and scripting concepts

**Quick Validation**: Verify you can navigate to `src/` folder to see component directories and access GitHub Copilot Chat.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on 02 - Repository Analysis Planning kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Repository Structure Research and Analysis (10 minutes)

**What You'll Do**: Conduct systematic research of repository organization to inform script design.

**Steps**:

1. **Explore** component directory structure using file navigation
   - [ ] Navigate through `src/000-cloud/` and `src/100-edge/` directories
   - [ ] Document component naming patterns, directory structures, and file organization
   - [ ] **Expected result**: Clear understanding of repository organization patterns

2. **Analyze** existing component patterns using search
   - [ ] Use GitHub Copilot Chat to analyze component structure patterns
   - [ ] Identify framework types (terraform, bicep), module organization, and naming conventions
   - [ ] **Expected result**: Documented component classification criteria and taxonomy

3. **Research** automated analysis approaches
   - [ ] Ask Copilot Chat for repository analysis script patterns and best practices
   - [ ] Identify tools and approaches for automated discovery and classification
   - [ ] **Expected result**: Understanding of scripting approaches and tools for repository analysis

### Task 2: Classification System Design (8 minutes)

**What You'll Do**: Design comprehensive classification taxonomy for repository components.

**Steps**:

1. **Define** component classification categories
   - [ ] Create taxonomy for component types (infrastructure, security, networking, compute, storage)
   - [ ] Design framework classification (terraform, bicep, mixed)
   - [ ] Plan deployment pattern tags (cloud-only, edge-only, hybrid)
   - [ ] **Expected result**: Complete classification schema for repository analysis

2. **Design** automated detection rules using AI assistance
   - [ ] Use Copilot Chat to design rules for automated component classification
   - [ ] Create criteria for identifying component purpose from file content and structure
   - [ ] Plan dependency detection through file analysis
   - [ ] **Expected result**: Automated classification rule set ready for implementation

### Task 3: Script Planning and Workflow Design (12 minutes)

**What You'll Do**: Create detailed implementation plan for repository analysis automation.

**Steps**:

1. **Plan** discovery script architecture with AI guidance
   - [ ] Design file system traversal approach for component discovery
   - [ ] Plan data collection methods for component metadata
   - [ ] Use Copilot Chat to optimize script structure and performance
   - [ ] **Expected result**: Complete script architecture with discovery workflows

2. **Design** classification automation workflow
   - [ ] Plan automated classification using defined taxonomy and rules
   - [ ] Design validation mechanisms for classification accuracy
   - [ ] Create error handling and edge case management approach
   - [ ] **Expected result**: Comprehensive classification workflow with quality controls

3. **Create** reporting and output planning
   - [ ] Design report formats (JSON, markdown, CSV) for different audiences
   - [ ] Plan data visualization approaches for component relationships
   - [ ] Use AI assistance to optimize report structure and usefulness
   - [ ] **Success criteria**: Complete task plan with discovery, classification, and reporting phases ready for implementation

## Completion Check

**Have you achieved systematic repository analysis planning?**

1. **Comprehensive Task Plan**: Did you create a complete task plan covering repository discovery, classification system design, and automated reporting with specific scripts and clear success criteria?
2. **Classification Taxonomy**: Did you design a systematic taxonomy for component classification with automated detection rules based on framework, purpose, and deployment patterns?
3. **Script Architecture**: Did you plan script workflows with error handling, validation checkpoints, and maintainable structure that others could implement?
4. **AI-Assisted Planning**: Did you demonstrate effective use of GitHub Copilot Chat for technical planning, workflow optimization, and systematic analysis approaches?

---

## Reference Appendix

### Help Resources

- **Learning Kata Coach** (`.github/agents/learning-kata-coach.agent.md`) - Interactive coaching for planning assistance with progress tracking
- **Task Planner** (`.github/prompts/task-planner.prompt.md`) - Specialized guidance for systematic task planning and implementation workflows
- **Project Components** (`src/` directory) - Real component examples for understanding structure, patterns, and classification approaches

### Professional Tips

- **Research First**: Explore existing repository structure and patterns before designing classification systems
- **Clear Taxonomy**: Define specific, measurable criteria for component classification that automated scripts can detect reliably
- **Iterative Refinement**: Start with basic discovery, then add classification, then reporting - validate each phase before proceeding

### Troubleshooting

- **Planning Too Technical**: Balance automation complexity with usability - scripts should be maintainable by others
- **Classification Unclear**: Include specific examples and detection patterns in your task plan to guide implementation

---

<!-- markdownlint-disable MD036 -->
*<!-- markdownlint-disable-file MD041 MD033 -->
<!-- markdownlint-enable MD033 -->

🤖 Crafted with precision by ✨Copilot following brilliant human instruction,

<!-- Reference Links -->
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
