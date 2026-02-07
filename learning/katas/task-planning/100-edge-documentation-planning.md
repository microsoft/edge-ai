---
title: 'Kata: 100 - Edge Documentation Planning'
description: Learn systematic task planning through practical documentation improvement using Azure project planning principles
author: Edge AI Team
ms.date: 2025-06-15
kata_id: task-planning-100-edge-documentation-planning
kata_category:
  - task-planning
kata_difficulty: 1
estimated_time_minutes: 45
learning_objectives:
  - Learn systematic documentation planning for Edge AI projects
  - Develop comprehensive documentation strategies and workflows
  - Create effective documentation structures for technical projects
  - Implement task planning methodologies for documentation initiatives
prerequisite_katas: []
technologies:
  - GitHub Copilot
success_criteria:
  - Create systematic documentation plan
  - Develop comprehensive documentation structure
  - Implement effective documentation workflows
  - Demonstrate stakeholder alignment and approval process
ai_coaching_level: guided
scaffolding_level: heavy
hint_strategy: progressive
common_pitfalls:
  - Creating documentation plans without considering user needs and workflows
  - Not establishing clear ownership and maintenance responsibilities
  - Failing to integrate documentation planning with development cycles
requires_azure_subscription: false
requires_local_environment: true
tags:
  - task-planning
search_keywords:
  - documentation-planning
  - task-breakdown
  - systematic-planning
  - technical-documentation
  - workflow-design
---

## Quick Context

Learn systematic task planning through practical documentation improvement using Azure project planning principles for Enterprise Edge AI projects.

## Essential Setup

**Learning Objectives**:

- Apply research-first approach to documentation projects
- Create comprehensive task plans with measurable success criteria
- Balance user needs with technical requirements

**Prerequisites**: VS Code, GitHub Copilot Chat, basic markdown experience

**Real-World Context**: Organizations struggle with inconsistent documentation that creates adoption barriers. This kata teaches systematic planning to address documentation challenges across edge AI implementations - from Digital Inspection guides to Predictive Maintenance instructions.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on 01 - Edge Documentation Planning kata and want interactive coaching with progress tracking.
> ```

**💡 Pro Tip**: Your coach can see your checkbox progress when you're using the local docs (`npm run docs`) and help you manage it! Navigate to the Learning section to access all learning resources.

### Setup Validation

Complete these prerequisite checks to ensure a successful learning experience:

**Required** (check these first):

- [ ] VS Code with GitHub Copilot extension active
- [ ] GitHub Copilot subscription and chat functionality enabled
- [ ] Access to project workspace with folder navigation capability
- [ ] Basic understanding of markdown and file navigation
- [ ] Awareness of three key project files — **Digital Inspection Scenario** (`docs/project-planning/scenarios/digital-inspection-survey/README.md`), **Task Planner Agent** (`.github/agents/task-planner.agent.md`), **Task Implementation Instructions** (`.github/instructions/task-implementation.instructions.md`)

**Quick Validation**: Verify you can open GitHub Copilot Chat and navigate to both `.github/agents/` and `docs/project-planning/scenarios/` folders.

**Understanding Check**: This kata teaches you the workflow from task planning through implementation using actual project tools and methodologies.

## Practice Tasks

**Scenario Context**:

The Digital Inspection & Survey documentation needs improvement based on user feedback: users can't understand platform capability relationships, missing step-by-step implementation guidance, unclear prerequisites cause failed deployments, and integration patterns need better documentation. Your challenge is to create a systematic task plan to enhance this documentation using
research-first planning: (1) Analyze current state and user needs, (2) Categorize improvements by impact/effort, (3) Create implementation roadmap with success metrics.

### Task 1: Documentation Analysis with File Exploration (10 minutes)

**What You'll Do**: Explore actual project files to understand documentation structure and identify improvement opportunities.

**Steps**:

1. **Navigate** to the Digital Inspection & Survey scenario documentation
   - [ ] Open the Digital Inspection Scenario (see Setup Validation above)
   - [ ] Review the file structure, organization, and content completeness
   - [ ] Note missing information and unclear explanations you find
   - [ ] **Expected result**: Clear understanding of current documentation state and specific gaps

2. **Explore** related documentation files
   - [ ] Navigate to the `docs/` folder and examine the structure
   - [ ] Open `docs/getting-started/` folder to see user onboarding patterns
   - [ ] Check `blueprints/` folder to understand implementation options
   - [ ] **Expected result**: Comprehensive view of how documentation connects across the project

3. **Research** user feedback patterns using GitHub Copilot
   - [ ] Use GitHub Copilot Chat: *"@workspace What are common user challenges with edge AI documentation based on the project structure?"*
   - [ ] Ask: *"What prerequisites and implementation guidance patterns do I see in this project?"*
   - [ ] Follow up with: *"Based on the blueprints and documentation structure, what integration patterns need better documentation?"*
   - [ ] **Expected result**: AI-assisted insights about user experience challenges with specific examples from the project

**Success Criteria**: Comprehensive analysis with specific file references documenting current state issues and prioritized improvement opportunities.

### Task 2: Improvement Strategy with Custom Agent Discovery (10 minutes)

**What You'll Do**: Discover and use the task planning custom agent to create an improvement roadmap.

**Steps**:

1. **Explore** the project's AI-assisted planning infrastructure
   - [ ] Navigate to `.github/agents/` folder
   - [ ] Open the Task Planner Agent (see Setup Validation above)
   - [ ] Read the first 50 lines to understand the task planning methodology
   - [ ] **Expected result**: Understanding of available AI planning tools and templates

2. **Practice with task planning custom agent**
   - [ ] In GitHub Copilot Chat, reference the task planner with *"Using the task planner methodology, help me categorize documentation improvements by impact and effort"*
   - [ ] Ask for phases with *"What phases should I define for implementing documentation enhancements with dependencies and timelines?"*
   - [ ] Try research-first approach with *"Based on the scenario, create a research-first planning approach for documentation improvements"*
   - [ ] **Expected result** — AI-generated improvement categories and implementation roadmap following project methodology

3. **Plan implementation phases using project methodology**
   - [ ] Categorize improvements you identified in Task 1 — **Quick wins** (simple updates with high user impact), **Content enhancement** (comprehensive additions and improvements), **Structural changes** (reorganization and navigation improvements)
   - [ ] Define phases, dependencies, effort estimates, and success metrics
   - [ ] **Expected result** — Detailed implementation plan with phases, timelines, and success metrics

**Success Criteria**: Structured improvement strategy with categorized enhancements and clear implementation roadmap created using project planning tools.

### Task 3: Task Plan Creation with Implementation Workflow (15 minutes)

**What You'll Do**: Create a comprehensive task plan and learn the transition from planning to implementation.

**Steps**:

1. **Create** a task plan using project templates
   - [ ] Open the Task Planner Agent and find the plan template (around line 130-200)
   - [ ] Study the template structure: Overview, Objectives, Research Summary, Implementation Plan, Dependencies, Success Criteria
   - [ ] Use GitHub Copilot Chat: *"Following the task planner template structure, create a task plan for improving Digital Inspection documentation with these phases: Research current state, Plan improvements, Implement changes, Validate results"*
   - [ ] Structure your plan following the template with **Research phase** (information gathering and analysis), **Planning phase** (strategy development and resource allocation), **Implementation phase** (content creation and improvement execution), **Validation phase** (testing, review, and iteration tasks)
   - [ ] **Expected result** — Professional task plan following exact project template structure with specific file references and actionable tasks

2. **Practice** the planning-to-implementation workflow transition
   - [ ] Save your task plan (you can create it in `.copilot-tracking/plans/` folder if available)
   - [ ] Open the Task Implementation Instructions (see Setup Validation above)
   - [ ] Read the first 100 lines to understand how plans transition to implementation
   - [ ] Ask GitHub Copilot: *"Explain how to transition from the task planning custom agent to using implementation instructions"*
   - [ ] **Expected result**: Clear understanding of complete workflow from planning through execution with practical transition steps

3. **Apply quality assurance planning methodology**
   - [ ] Add quality assurance elements to your task plan including review processes and approval workflows
   - [ ] Add testing methodology and validation approaches to your plan
   - [ ] Add feedback collection mechanisms to your plan
   - [ ] Add maintenance and update procedures to your plan
   - [ ] **Expected result** — Comprehensive task plan with built-in quality assurance framework

**Success Criteria**: Professional task plan with actionable tasks, success criteria, quality assurance framework, and understanding of implementation workflow transition.

### Task 4: Complete Workflow Practice - Planning to Implementation (10 minutes)

**What You'll Do**: Experience the complete workflow from planning through implementation using project tools.

**Steps**:

1. **Create** a simple task plan using the methodology you learned
   - [ ] Use GitHub Copilot with task planner methodology: *"Create a 3-task plan for improving one section of the Digital Inspection documentation"*
   - [ ] Structure your plan with these phases — **Research** (gather information), **Implementation** (make specific improvements), **Validation** (test and review)
   - [ ] **Expected result**: Simple but complete task plan following project template structure

2. **Transition** to implementation mode
   - [ ] Ask GitHub Copilot: *"Following the task implementation instructions, how would I implement the first task in my plan?"*
   - [ ] Practice the systematic approach: read referenced files, gather context, implement with working results
   - [ ] Try: *"What specific files should I examine and what tools should I use for implementation?"*
   - [ ] **Expected result**: Understanding of how to move from planning to systematic implementation

3. **Validate** your workflow understanding
   - [ ] Explain to GitHub Copilot what you learned: *"I learned to use task planning custom agent for strategy, then switch to implementation instructions for systematic execution"*
   - [ ] Ask for confirmation: *"Is this the correct workflow pattern for this project?"*
   - [ ] **Expected result**: Confirmed understanding of complete planning-to-implementation workflow

**Success Criteria**: Demonstration of complete workflow understanding from task planning through implementation with practical experience using both planning and implementation tools.

### Complete Workflow Demonstration: From Planning to Implementation

**Real Example**: Here's how the complete workflow works in practice:

**Step 1: Planning Phase Example**:

- **Scenario**: You need to improve the Digital Inspection documentation
- **Use task planner**: *"Using task-planner custom agent, create a plan to add missing prerequisites section to Digital Inspection documentation"*
- **Create research notes**: Save findings in `.copilot-tracking/research/` if working on real projects
- **Expected output**: Comprehensive plan with research, implementation, and validation phases

**Step 2: Implementation Phase Transition**:

- **Switch modes**: Open the Task Implementation Instructions (see Setup Validation above)
- **Follow systematic process**:
  1. Read the complete plan file to understand scope
  2. Gather ALL required context (read referenced files)
  3. Implement tasks systematically in order
  4. Mark tasks complete [x] and track progress
- **Expected behavior**: Systematic execution following plan exactly

**Step 3: Implementation Example**:

- **Task**: "Add prerequisites section to documentation"
- **Systematic approach**:
  1. Read current documentation file
  2. Analyze existing patterns for prerequisites
  3. Create working content that meets requirements
  4. Validate implementation and fix issues
  5. Mark task complete [x]
- **Expected result**: Working implementation that meets all task requirements

**Step 4: Validation and Iteration**:

- **Use prompts for guidance**: *"Review my implementation and suggest improvements"
- **Quality check**: Ensure implementation meets success criteria
- **Continue or iterate**: Based on validation results
- **Expected outcome**: High-quality implementation ready for use

**Workflow Transition Indicators**:

- ✅ **Ready for implementation**: Plan has specific file paths, clear actions, defined success criteria
- ⚠️ **Need more planning**: Vague tasks, unclear requirements, missing context
- 🔄 **Ready for validation**: Implementation complete, need quality review and feedback

**Custom Agent Discovery and Exploration Exercise**:

**Practice Exercise**: Discover and explore the available AI assistance modes:

**1. Explore the Custom Agents Infrastructure**:

- Navigate to `.github/agents/` folder in your file explorer
- List all available custom agent files:
  - `task-planner.agent.md` - for systematic planning
  - `prompt-builder.agent.md` - for prompt engineering
  - `learning-kata-coach.agent.md` - for learning assistance
  - `learning-lab-coach.agent.md` - for lab guidance
- **Expected result**: Understanding of available specialized AI assistance modes

**2. Deep Dive into Task Planner Custom Agent**:

- Open the Task Planner Agent
- Read lines 1-50 to understand the specialized planning approach
- Find the planning template (around line 100) and examine its structure
- Ask GitHub Copilot: *"Explain the task planner custom agent methodology and when I should use it"*
- **Expected result**: Clear understanding of task planning methodology and template structure

**3. Practice Custom Agent Usage**:

- Try this command: *"Using the task-planner custom agent approach, help me create a research plan for understanding edge AI documentation patterns"*
- Compare with general chat: *"Help me create a research plan for understanding edge AI documentation patterns"*
- Notice the difference in specificity and methodology
- **Expected result**: Experience with specialized vs general AI assistance approaches

**4. Validation of Custom Agent Understanding**:

- Ask: *"When should I use task-planner custom agent vs prompt files vs instruction files for AI assistance?"*
- Verify your understanding: *"I should use task-planner custom agent when I need to create systematic plans, prompts when I need guidance, and instructions when I need to implement plans. Is this correct?"*
- **Expected result**: Confirmed understanding of when to use each assistance approach

**File-Specific Exploration and Validation Checkpoints**:

**Validation Exercise**: Confirm your understanding through specific file exploration:

**1. Task Planning Template Structure Validation**:

- Open `.github/agents/task-planner.agent.md` and go to line 100-150
- Find the plan template section and examine the required elements:
  - Overview and Objectives sections
  - Research Summary with file references
  - Implementation Plan with phases and tasks
  - Dependencies and Success Criteria
- Ask: *"What are the required elements of a task plan according to the template?"*
- **Expected result**: Understanding of professional task plan structure requirements

**2. Implementation Instructions Deep Dive**:

- Open the Task Implementation Instructions (see Setup Validation above) and read lines 1-100
- Find the "Core Implementation Process" section
- Identify the systematic implementation workflow steps
- Ask: *"What is the systematic process for implementing task plans according to the instructions?"*
- **Expected result**: Understanding of how plans transition to implementation with specific steps

**3. Real Scenario Documentation Analysis**:

- Open the Digital Inspection Scenario
- Read the first 50 lines to understand the scenario structure
- Identify what information is provided vs what might be missing
- Ask: *"Based on this scenario structure, what documentation improvements would have the highest impact?"*
- **Expected result**: Practical understanding of documentation analysis with specific improvement opportunities

## Completion Check

*Before marking this kata complete, verify your understanding:*

1. **Describe** your research-first planning approach for the Digital Inspection documentation. What specific analysis steps did you take to identify improvement opportunities?
2. **Explain** how you categorized documentation improvements by impact and effort. What criteria determined whether something was a quick win versus a structural change?
3. **What** phases did you define in your implementation roadmap? How do they build upon each other with clear dependencies?
4. **How** did you use the task-planner custom agent to create your improvement strategy? What specific prompts generated the most valuable planning insights?
5. **Describe** your success metrics for the documentation enhancements. How will you measure whether the improvements achieve their intended impact?

---

## Reference Appendix

### Help Resources

- **Task Planning Custom Agent** - See Setup Validation section for full path and description
- **Digital Inspection & Survey Scenario** - See Setup Validation section for full path and description
- **Task Implementation Instructions** - See Setup Validation section for full path and description
- **Getting Started Guide** `docs/getting-started/` - User onboarding patterns to understand documentation structure
- **Blueprint Documentation** `blueprints/` - Implementation options that need better documentation

### Professional Tips

- Start with comprehensive file exploration before creating plans to ground your strategy in actual project structure
- Use AI-assisted planning for categorization and roadmap creation, but validate suggestions against project standards
- Define clear success metrics for each improvement category to measure impact objectively
- Document dependencies between phases to ensure implementation follows logical sequence
- Balance quick wins with structural improvements to maintain momentum while addressing root causes

### Troubleshooting

- **Analysis feels too broad** → Focus on specific user feedback examples (unclear prerequisites, missing integration patterns) and trace them to exact files
- **Categorization unclear** → Use the impact/effort matrix explicitly: high-impact + low-effort = quick wins, high-impact + high-effort = strategic initiatives
- **Implementation roadmap overwhelming** → Break into 3-4 clear phases with no more than 5-7 tasks per phase, ensure each phase delivers standalone value

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
