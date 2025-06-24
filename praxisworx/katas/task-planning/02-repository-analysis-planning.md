---
title: 02 - Repository Analysis Planning
description: Master systematic task planning for repository analysis scripting through component tagging and classification workflows
author: Edge AI Team
ms.date: 2025-06-18
ms.topic: kata
estimated_reading_time: 8
difficulty: intermediate
duration: 30-40 minutes
keywords:
  - praxisworx
  - task planning
  - repository analysis
  - scripting workflows
  - component classification
  - numbered progression
---

## What You'll Learn

Create comprehensive task plans for repository analysis projects using systematic planning methodology.

**Learning Objectives**:

- Apply research-driven approach to repository analysis and scripting projects
- Create detailed task plans for automated component discovery and classification
- Balance automation efficiency with accuracy requirements
- Design workflows for data analysis and reporting

**Prerequisites**: Completion of "01 - Edge Documentation Planning" kata, VS Code with GitHub Copilot, basic scripting experience

**Real-World Context**: Large repositories require systematic analysis to understand component relationships, dependencies, and classification patterns. This kata teaches planning approaches for creating scripts that analyze repository structure, tag components by type and purpose, and generate classification reports for better project organization.

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
I'm working on Repository Analysis Planning kata and want interactive coaching with progress tracking and learning evaluation.
```

**💡 Pro Tip**: Your coach can see your checkbox progress when you're using the local docs (`npm run docs:training`) and help you manage it!

### Essential Setup

**Required** (check these first):

- [ ] Completion of Edge Documentation Planning kata (01) for methodology foundation
- [ ] VS Code with GitHub Copilot extension active and chat functionality enabled
- [ ] Access to project workspace with ability to explore repository structure
- [ ] Basic understanding of file system navigation and scripting concepts

**Quick Validation**: Can you navigate to `src/` folder and see component directories? Can you access GitHub Copilot Chat for planning assistance?

## Practice Scenario

Your team needs to analyze the edge AI repository to understand component organization and create automated classification for better project management:

**Analysis Requirements**:

- **Component Discovery**: Systematically identify all components across `src/000-cloud/` and `src/100-edge/` directories
- **Classification System**: Tag components by framework (terraform, bicep), purpose (security, networking, compute), and deployment patterns
- **Dependency Mapping**: Understand component relationships and dependencies
- **Reporting Automation**: Generate structured reports for team consumption

**Your Challenge**: Create a systematic task plan for building repository analysis scripts that can automatically discover, classify, and report on repository components while ensuring accuracy and maintainability.

**Methodology**: Use research-first planning: (1) Explore repository structure comprehensively, (2) Design classification taxonomy, (3) Plan automated discovery workflows, (4) Create validation and reporting systems

## Practice Tasks

### Task 1: Repository Structure Research and Analysis (10 minutes)

**What You'll Do**: Conduct systematic research of repository organization to inform script design.

**Steps**:

1. **Explore** component directory structure using file navigation
   - [ ] Navigate through `src/000-cloud/` and `src/100-edge/` directories
   - [ ] Document component naming patterns, directory structures, and file organization
   - **Expected result**: Clear understanding of repository organization patterns

2. **Analyze** existing component patterns using search
   - [ ] Use GitHub Copilot Chat to analyze component structure patterns
   - [ ] Identify framework types (terraform, bicep), module organization, and naming conventions
   - **Expected result**: Documented component classification criteria and taxonomy

3. **Research** automated analysis approaches
   - [ ] Ask Copilot Chat for repository analysis script patterns and best practices
   - [ ] Identify tools and approaches for automated discovery and classification
   - **Expected result**: Understanding of scripting approaches and tools for repository analysis

### Task 2: Classification System Design (8 minutes)

**What You'll Do**: Design comprehensive classification taxonomy for repository components.

**Steps**:

1. **Define** component classification categories
   - [ ] Create taxonomy for component types (infrastructure, security, networking, compute, storage)
   - [ ] Design framework classification (terraform, bicep, mixed)
   - [ ] Plan deployment pattern tags (cloud-only, edge-only, hybrid)
   - **Expected result**: Complete classification schema for repository analysis

2. **Design** automated detection rules using AI assistance
   - [ ] Use Copilot Chat to design rules for automated component classification
   - [ ] Create criteria for identifying component purpose from file content and structure
   - [ ] Plan dependency detection through file analysis
   - **Expected result**: Automated classification rule set ready for implementation

### Task 3: Script Planning and Workflow Design (12 minutes)

**What You'll Do**: Create detailed implementation plan for repository analysis automation.

**Steps**:

1. **Plan** discovery script architecture with AI guidance
   - [ ] Design file system traversal approach for component discovery
   - [ ] Plan data collection methods for component metadata
   - [ ] Use Copilot Chat to optimize script structure and performance
   - **Expected result**: Complete script architecture with discovery workflows

2. **Design** classification automation workflow
   - [ ] Plan automated classification using defined taxonomy and rules
   - [ ] Design validation mechanisms for classification accuracy
   - [ ] Create error handling and edge case management approach
   - **Expected result**: Comprehensive classification workflow with quality controls

3. **Create** reporting and output planning
   - [ ] Design report formats (JSON, markdown, CSV) for different audiences
   - [ ] Plan data visualization approaches for component relationships
   - [ ] Use AI assistance to optimize report structure and usefulness
   - **Success criteria**: Complete task plan with discovery, classification, and reporting phases ready for implementation

## Validation

**You've Succeeded When**:

- [ ] Created comprehensive task plan covering repository discovery, classification, and reporting
- [ ] Designed systematic taxonomy for component classification with automated detection rules
- [ ] Planned script architecture with clear workflows, error handling, and validation
- [ ] Demonstrated use of AI assistance for technical planning and optimization

**Quality Check**: Your task plan should include specific scripts to create, clear success criteria for each phase, and systematic approach to repository analysis that others could implement.

## Next Steps

**Continue Learning**: Practice with "03 - Advanced Capability Integration" kata to apply planning skills to complex multi-component scenarios

**Apply Skills**: Use repository analysis planning techniques for actual project organization and discovery tasks

## Resources

- **PraxisWorx Kata Coach**: Use [kata coaching guidance][kata-coach] for step-by-step help and troubleshooting
- **Task Planner**: Use [systematic planning guidance][task-planner] for structured task creation workflows
- **GitHub Copilot Chat**: Use for repository analysis planning, scripting guidance, and workflow optimization
- **Project Components**: Reference `src/` directory structure for real component examples

[kata-coach]: /.github/chatmodes/praxisworx-kata-coach.chatmode.md
[task-planner]: /.github/prompts/task-planner.prompt.md

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
