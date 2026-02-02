---
title: 'Kata: 400 - AI Asset Extraction'
description: Learn systematic extraction and packaging of AI prompts, instructions, and agents for client project delivery using comprehensive task planning and system...
author: Edge AI Team
ms.date: 2025-06-21
kata_id: task-planning-400-ai-asset-extraction
kata_category:
  - task-planning
kata_difficulty: 4
estimated_time_minutes: 120
learning_objectives:
  - Learn AI asset identification and extraction techniques
  - Develop systematic asset cataloging and organization skills
  - Create reusable asset management workflows
prerequisite_katas:
  - task-planning-100-edge-documentation-planning
  - task-planning-300-repository-analysis-planning
technologies:
  - GitHub Copilot
success_criteria:
  - Learn systematic AI asset identification and extraction techniques
  - Implement comprehensive asset cataloging and organization systems
  - Create reusable client delivery workflows and documentation packages
  - Demonstrate proficiency in client project integration methodologies
ai_coaching_level: guided
scaffolding_level: light
hint_strategy: progressive
common_pitfalls:
  - 'Incomplete asset discovery: Always use systematic search methods to find all AI assets'
  - 'Poor client integration: Design for seamless client project structure integration'
requires_azure_subscription: false
requires_local_environment: true
tags:
  - task-planning
search_keywords:
  - ai-asset-extraction
  - prompt-management
  - agent-packaging
  - client-delivery
  - asset-cataloging
---

## Quick Context

**You'll Learn**: Become proficient in systematic extraction and packaging of AI assets for client delivery through comprehensive task planning and systematic implementation methodology.

**Prerequisites**: Completion of previous task planning katas, understanding of prompts/instructions/agents, experience with systematic implementation workflow

**Real Challenge**: Client engagements often require packaging and transferring sophisticated AI capabilities from your project to client systems. This kata teaches systematic approaches to identify, extract, and package AI assets (prompts, instructions, agents) while maintaining clean project structure and providing seamless integration capabilities.

## Essential Setup

Complete these prerequisite checks to ensure a successful learning experience:

**Required** (check these first):

- [ ] VS Code with GitHub Copilot extension active
- [ ] GitHub Copilot subscription and chat functionality enabled
- [ ] Access to project workspace with folder navigation capability
- [ ] Understanding of task implementation instructions methodology
- [ ] Completion of Edge Documentation Planning and Repository Analysis Planning katas

**Quick Validation**: Verify you can open GitHub Copilot Chat, access Task Planner custom agent, and navigate to `.github/` folders.

**Understanding Check**: This kata teaches the complete workflow from asset discovery through systematic task planning to implementation using the project's systematic implementation methodology.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on 04 - AI Asset Extraction kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: AI Asset Discovery and Cataloging (20 minutes)

**What You'll Do**: Systematically discover and catalog all AI assets suitable for client delivery

**Steps**:

1. **Catalog** prompts for client delivery
   - [ ] Navigate to `.github/prompts/` and list all available prompt files
   - [ ] Analyze each prompt for client delivery suitability (generic vs. project-specific)
   - [ ] Identify prompts that would benefit Tailspin Toys' Edge Insights development
   - [ ] Document prompt purposes and integration requirements in a markdown catalog
   - [ ] **Expected result**: Comprehensive catalog of deliverable prompts with suitability analysis

2. **Catalog** instructions for systematic development
   - [ ] Navigate to `.github/instructions/` and examine all instruction files
   - [ ] Evaluate instructions for reusability in client environment
   - [ ] Identify instructions that support systematic development workflows
   - [ ] Document instruction purposes and client customization needs
   - [ ] **Expected result**: Complete catalog of deliverable instructions with customization requirements

3. **Catalog** agents for specialized workflows
   - [ ] Navigate to `.github/agents/` and analyze all agent configurations
   - [ ] Assess agents for applicability to client development workflows
   - [ ] Document agent capabilities and integration considerations
   - [ ] **Success check**: Comprehensive asset catalog with delivery suitability and integration requirements documented

### Task 2: Task Plan Creation Using Task Planner Custom Agent (20 minutes)

**What You'll Do**: Create a comprehensive task plan using Task Planner custom agent for systematic asset extraction and packaging

**Steps**:

1. **Design** project structure for client delivery
   - [ ] Plan folder structure for Tailspin Toys Edge Insights integration
   - [ ] Design asset organization (prompts, instructions, agents) for easy discovery
   - [ ] Plan documentation structure for client onboarding and integration
   - [ ] Create naming conventions that align with client project standards
   - [ ] **Expected result**: Complete project structure design for seamless client integration

2. **Create** comprehensive extraction task plan using Task Planner custom agent
   - [ ] Switch to Task Planner custom agent in GitHub Copilot Chat
   - [ ] Ask: *"Create a comprehensive task plan for extracting AI assets (prompts, instructions, agents) from Edge-AI project for Tailspin Toys Edge Insights delivery"*
   - [ ] Follow Task Planner methodology to create systematic implementation plan
   - [ ] Include asset copying, customization, and documentation tasks in the plan
   - [ ] Plan integration script development (PowerShell or Bash) for automated deployment to the target project with merge capabilities
   - [ ] Design script to handle existing file conflicts and selective asset integration
   - [ ] Plan validation and testing tasks for delivery quality assurance
   - [ ] Document task dependencies and execution sequence following project methodology
   - [ ] **Expected result**: Detailed task plan created using Task Planner custom agent and saved in `.copilot-tracking/plans/` folder

3. **Plan** delivery package validation
   - [ ] Design validation criteria for complete asset package
   - [ ] Plan testing procedures for integration script functionality
   - [ ] Create delivery checklist for client handover quality assurance
   - [ ] **Success check**: Complete task plan ready for systematic implementation execution with validation criteria

### Task 3: Systematic Implementation Execution (15 minutes)

**What You'll Do**: Execute the task plan using systematic implementation methodology and task implementation instructions

**Steps**:

1. **Switch** to systematic implementation approach
   - [ ] Reference `.github/instructions/task-implementation.instructions.md` for systematic execution methodology
   - [ ] Verify your task plan is properly saved in `.copilot-tracking/plans/` folder
   - [ ] Begin systematic implementation following the task implementation instructions
   - [ ] Use the plan analysis and preparation process to understand scope and objectives
   - [ ] **Expected result**: Systematic implementation initiated with proper task plan structure and methodology understanding

2. **Execute** systematic asset extraction following task implementation instructions
   - [ ] Follow systematic implementation process to implement asset copying and organization
   - [ ] Create the planned folder structure in a new `tailspin-toys-edge-insights/` directory
   - [ ] Copy and customize assets according to task plan specifications
   - [ ] Implement comprehensive integration script with merge capabilities (see script requirements below)
   - [ ] Mark tasks complete in plan file as you progress through implementation
   - [ ] **Expected result**: Complete asset extraction with organized deliverable package following systematic methodology

3. **Validate** delivery package completeness
   - [ ] Test integration script functionality and error handling in sandbox environment
   - [ ] Verify script handles existing project structure conflicts appropriately
   - [ ] Test dry-run mode and validate backup creation functionality
   - [ ] Verify all planned assets are included and properly organized
   - [ ] Create comprehensive delivery documentation for Tailspin Toys integration
   - [ ] Document script usage examples and troubleshooting guide
   - [ ] Document any customization requirements or integration considerations
   - **Success criteria**: Complete, tested deliverable package ready for client integration with comprehensive documentation and reliable merge capabilities

## Completion Check

Have you achieved AI asset extraction excellence?

1. **Systematic Asset Discovery**: Can you identify and catalog all AI assets (prompts, instructions, agents) with delivery suitability analysis?
2. **Client-Ready Packaging**: Can you organize assets with clean structure and comprehensive documentation for seamless client integration?
3. **Smart Integration Automation**: Can you create deployment scripts with conflict detection, backup capabilities, and dry-run testing?
4. **Professional Delivery Excellence**: Can you produce complete, tested deliverables with integration guidance and troubleshooting documentation?

---

## Reference Appendix

### Help Resources

- **Task Implementation Instructions** (`.github/instructions/task-implementation.instructions.md`): Systematic execution methodology for complex implementation projects
- **Task Planner Custom Agent** (`.github/agents/task-planner.agent.md`): AI-assisted systematic planning methodology and workflow guidance
- **Learning Kata Coach** (`.github/agents/learning-kata-coach.agent.md`): Interactive learning support with progress tracking and hints
- **Shell Script Instructions** (`.github/instructions/shell.instructions.md`): Guidelines for Bash and PowerShell script development

### Professional Tips

- **Start with Discovery**: Use systematic search methods (grep, find) to ensure complete asset identification before planning
- **Design for Non-Disruption**: Create scripts that detect existing structures and provide safe merge options with backups
- **Test Before Delivery**: Always run dry-run mode first, validate on test environment, document any edge cases discovered

### Troubleshooting

- **Asset Discovery Incomplete**: Use multiple search methods (file patterns, content search), review project documentation structure
- **Integration Script Complexity**: Break into functions (detect, backup, merge, validate), test each function independently

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
