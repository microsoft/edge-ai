---
title: 01 - Edge Documentation Planning
description: Learn systematic task planning through practical documentation improvement using Azure project planning principles
author: Edge AI Team
ms.date: 2025-06-15
ms.topic: kata
estimated_reading_time: 15
difficulty: beginner
duration: 25-35 minutes
keywords:
  - praxisworx
  - task planning
  - documentation
  - edge computing
---

## What You'll Learn

Create actionable task plans for documentation improvement projects using systematic planning methodology.

**Learning Objectives**:

- Apply research-first approach to documentation projects
- Create comprehensive task plans with measurable success criteria
- Balance user needs with technical requirements

**Prerequisites**: VS Code, GitHub Copilot Chat, basic markdown experience

**Real-World Context**: Organizations struggle with inconsistent documentation that creates adoption barriers. This kata teaches systematic planning to address documentation challenges across edge AI implementations - from Digital Inspection guides to Predictive Maintenance instructions.

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
I'm working on Edge Documentation Planning kata and want interactive coaching with progress tracking and learning evaluation.
```

**💡 Pro Tip**: Your coach can see your checkbox progress when you're using the local docs (`npm run docs:training`) and help you manage it!

### Essential Setup

**Required** (check these first):

- [ ] VS Code with GitHub Copilot extension active
- [ ] GitHub Copilot subscription and chat functionality enabled
- [ ] Access to project workspace with folder navigation capability
- [ ] Basic understanding of markdown and file navigation

**Quick Validation**:

- Can you navigate to `.github/chatmodes/` folder and see task-planner.chatmode.md?
- Can you open GitHub Copilot Chat and see the chat interface?
- Can you open `docs/project-planning/scenarios/` and find digital-inspection-survey folder?

**Understanding Check**: This kata teaches you the workflow from task planning through implementation using actual project tools and methodologies.

## Practice Scenario

The Digital Inspection & Survey documentation needs improvement based on user feedback:

- Users can't understand platform capability relationships
- Missing step-by-step implementation guidance
- Unclear prerequisites cause failed deployments
- Integration patterns need better documentation

**Your Challenge**: Create a systematic task plan to enhance this documentation, improve user experience, and increase successful implementation rates.

**Methodology**: Use research-first planning: (1) Analyze current state and user needs, (2) Categorize improvements by impact/effort, (3) Create implementation roadmap with success metrics

## Understanding AI-Assisted Planning Tools

Before starting the tasks, you need to understand the three key AI assistance approaches in this project:

### Prompts vs Instructions vs Chat Modes

**Prompts** (`.prompt.md` files in `.github/prompts/`):

- **Purpose**: Coaching and guidance approach
- **When to use**: When you need step-by-step guidance and context-aware assistance
- **Example practice**: Open `.github/prompts/getting-started.prompt.md` and notice the coaching structure
- **Try this**: In GitHub Copilot Chat, ask: *"@workspace help me understand the project structure using getting started guidance"*

**Instructions** (`.instructions.md` files in `.github/instructions/`):

- **Purpose**: Automated implementation with specific rules
- **When to use**: When you have a plan and need systematic implementation guidance
- **Example practice**: Open `.github/instructions/task-implementation.instructions.md` and see the systematic process
- **Try this**: Ask Copilot: *"Following the task implementation instructions, what steps should I take for systematic development?"*

**Chat Modes** (`.chatmode.md` files in `.github/chatmodes/`):

- **Purpose**: Specialized AI assistance modes for specific workflows
- **When to use**: When you need focused assistance for particular tasks like planning or prompt building
- **Example practice**: Open `.github/chatmodes/task-planner.chatmode.md` and examine the specialized planning methodology
- **Try this**: Ask: *"Using the task planner chat mode, help me understand how to create research-first plans"*

### Hands-on Practice: Prompts vs Instructions vs Chat Modes

**Practice Exercise**: Try these specific examples to understand the differences:

**1. Prompt Practice** (coaching approach):

- Open `.github/prompts/getting-started.prompt.md`
- In GitHub Copilot Chat, ask: *"@workspace Using the getting started prompt approach, help me understand how to deploy a blueprint"*
- Notice how you get step-by-step guidance and context-aware coaching
- **Expected result**: Conversational, educational guidance that helps you understand concepts

**2. Instruction Practice** (systematic implementation):

- Open `.github/instructions/task-implementation.instructions.md`
- Ask: *"Following the systematic implementation process in task-implementation.instructions.md, what are the exact steps to implement a task plan?"*
- Notice how you get specific, ordered procedures for execution
- **Expected result**: Systematic, step-by-step implementation methodology with exact procedures

**3. Chat Mode Practice** (specialized assistance):

- Open `.github/chatmodes/task-planner.chatmode.md`
- Ask: *"Using the task-planner chat mode methodology, help me create a plan for documenting a new feature"*
- Notice how you get specialized planning assistance with templates and standards
- **Expected result**: Focused planning assistance following project-specific methodology

**When to Use Each Approach**:

- **Prompts**: When learning, getting started, or need guidance and context
- **Instructions**: When implementing, following procedures, or need systematic execution
- **Chat Modes**: When doing specialized work like planning, prompt engineering, or specific project workflows

### Workflow Understanding

**The Complete Workflow**: Planning → Implementation → Validation

1. **Planning Phase**: Use chat modes and prompts for guidance and strategy creation
2. **Implementation Phase**: Switch to instructions for systematic execution
3. **Validation Phase**: Use prompts for review and improvement guidance

**Your Goal**: Master this workflow transition through hands-on practice in the following tasks.

## Understanding the Complete AI-Assisted Development Workflow

### From Planning to Implementation: The Project Methodology

This section teaches you the essential workflow transition that professional AI-assisted developers use:

**Phase 1: Research and Planning** (using chat modes and prompts)

1. **Start with research**: Use chat modes like `task-planner.chatmode.md` for specialized assistance
2. **Get guidance**: Use prompt files for coaching-style help when you need direction
3. **Create plans**: Generate comprehensive task plans with research, implementation, and validation phases

**Phase 2: Implementation** (switching to instructions)

1. **Switch to systematic mode**: Open `.github/instructions/task-implementation.instructions.md`
2. **Follow the process**: Read plan files completely, gather context, implement systematically
3. **Track progress**: Mark tasks complete and update changes files for releases

**Phase 3: Validation and Iteration** (back to prompts for guidance)

1. **Review and validate**: Use prompts for guidance on review processes
2. **Get feedback**: Ask AI for improvement suggestions and quality checks
3. **Iterate and improve**: Continue the cycle for continuous improvement

### Key Workflow Transitions

**When to switch from Planning to Implementation**:

- You have a complete task plan with specific, actionable tasks
- All research and strategy work is documented
- You're ready to create/modify actual files systematically

**How to make the transition**:

1. Save your plan in `.copilot-tracking/plans/` folder
2. Reference the task-implementation instructions
3. Start systematic implementation following the plan exactly

**Indicators you're ready for implementation**:

- [ ] Plan has specific file paths and actions
- [ ] Success criteria are clearly defined
- [ ] Dependencies and phases are identified
- [ ] You understand what working code/content needs to be created

## Tasks

### Task 1: Documentation Analysis with File Exploration (10 minutes)

**What You'll Do**: Explore actual project files to understand documentation structure and identify improvement opportunities.

**Steps**:

1. **Navigate** to the Digital Inspection & Survey scenario documentation
   - [ ] Open the file: `docs/project-planning/scenarios/digital-inspection-survey/README.md`
   - [ ] Review the file structure, organization, and content completeness
   - [ ] Note missing information and unclear explanations you find
   - **Expected result**: Clear understanding of current documentation state and specific gaps

2. **Explore** related documentation files
   - [ ] Navigate to the `docs/` folder and examine the structure
   - [ ] Open `docs/getting-started/` folder to see user onboarding patterns
   - [ ] Check `blueprints/` folder to understand implementation options
   - **Expected result**: Comprehensive view of how documentation connects across the project

3. **Research** user feedback patterns using GitHub Copilot
   - [ ] Use GitHub Copilot Chat: *"@workspace What are common user challenges with edge AI documentation based on the project structure?"*
   - [ ] Ask: *"What prerequisites and implementation guidance patterns do I see in this project?"*
   - [ ] Follow up with: *"Based on the blueprints and documentation structure, what integration patterns need better documentation?"*
   - **Expected result**: AI-assisted insights about user experience challenges with specific examples from the project

**Success Criteria**: Comprehensive analysis with specific file references documenting current state issues and prioritized improvement opportunities.

### Task 2: Improvement Strategy with Chat Mode Discovery (10 minutes)

**What You'll Do**: Discover and use the task planning chat mode to create an improvement roadmap.

**Steps**:

1. **Explore** the project's AI-assisted planning infrastructure
   - [ ] Navigate to `.github/chatmodes/` folder
   - [ ] Open the file: `.github/chatmodes/task-planner.chatmode.md`
   - [ ] Read the first 50 lines to understand the task planning methodology
   - **Expected result**: Understanding of available AI planning tools and templates

2. **Practice** with task planning chat mode
   - [ ] In GitHub Copilot Chat, reference the task planner: *"Using the task planner methodology from .github/chatmodes/task-planner.chatmode.md, help me categorize documentation improvements by impact and effort"*
   - [ ] Ask: *"What phases should I define for implementing documentation enhancements with dependencies and timelines?"*
   - [ ] Try: *"Based on the Digital Inspection scenario, create a research-first planning approach for documentation improvements"*
   - **Expected result**: AI-generated improvement categories and implementation roadmap following project methodology

3. **Plan** implementation phases using project methodology
   - [ ] Categorize improvements you identified in Task 1:
     - Quick wins: simple updates with high user impact
     - Content enhancement: comprehensive additions and improvements
     - Structural changes: reorganization and navigation improvements
   - [ ] Define phases, dependencies, effort estimates, and success metrics
   - **Expected result**: Detailed implementation plan with phases, timelines, and success metrics

**Success Criteria**: Structured improvement strategy with categorized enhancements and clear implementation roadmap created using project planning tools.

### Task 3: Task Plan Creation with Implementation Workflow (15 minutes)

**What You'll Do**: Create a comprehensive task plan and learn the transition from planning to implementation.

**Steps**:

1. **Create** a task plan using project templates
   - [ ] Open `.github/chatmodes/task-planner.chatmode.md` and find the plan template (around line 130-200)
   - [ ] Study the template structure: Overview, Objectives, Research Summary, Implementation Plan, Dependencies, Success Criteria
   - [ ] Use GitHub Copilot Chat: *"Following the task planner template structure from .github/chatmodes/task-planner.chatmode.md, create a task plan for improving Digital Inspection documentation with these phases: Research current state, Plan improvements, Implement changes, Validate results"*
   - [ ] Structure your plan following the template with:
     - **Research phase**: Information gathering and analysis tasks
     - **Planning phase**: Strategy development and resource allocation
     - **Implementation phase**: Content creation and improvement execution
     - **Validation phase**: Testing, review, and iteration tasks
   - **Expected result**: Professional task plan following exact project template structure with specific file references and actionable tasks

2. **Practice** the planning-to-implementation workflow transition
   - [ ] Save your task plan (you can create it in `.copilot-tracking/plans/` folder if available)
   - [ ] Open the file: `.github/instructions/task-implementation.instructions.md`
   - [ ] Read the first 100 lines to understand how plans transition to implementation
   - [ ] Ask GitHub Copilot: *"Explain how to transition from the task planning chat mode to using implementation instructions"*
   - **Expected result**: Clear understanding of complete workflow from planning through execution with practical transition steps

3. **Apply** quality assurance planning methodology
   - [ ] Add quality assurance elements to your task plan:
     - Review processes and approval workflows
     - Testing methodology and validation approaches
     - Feedback collection mechanisms
     - Maintenance and update procedures
   - **Expected result**: Comprehensive task plan with built-in quality assurance framework

**Success Criteria**: Professional task plan with actionable tasks, success criteria, quality assurance framework, and understanding of implementation workflow transition.

### Task 4: Complete Workflow Practice - Planning to Implementation (10 minutes)

**What You'll Do**: Experience the complete workflow from planning through implementation using project tools.

**Steps**:

1. **Create** a simple task plan using the methodology you learned
   - [ ] Use GitHub Copilot with task planner methodology: *"Create a 3-task plan for improving one section of the Digital Inspection documentation"*
   - [ ] Structure your plan with:
     - Research phase (gather information)
     - Implementation phase (make specific improvements)
     - Validation phase (test and review)
   - **Expected result**: Simple but complete task plan following project template structure

2. **Transition** to implementation mode
   - [ ] Ask GitHub Copilot: *"Following .github/instructions/task-implementation.instructions.md, how would I implement the first task in my plan?"*
   - [ ] Practice the systematic approach: read referenced files, gather context, implement with working results
   - [ ] Try: *"What specific files should I examine and what tools should I use for implementation?"*
   - **Expected result**: Understanding of how to move from planning to systematic implementation

3. **Validate** your workflow understanding
   - [ ] Explain to GitHub Copilot what you learned: *"I learned to use task planning chat mode for strategy, then switch to implementation instructions for systematic execution"*
   - [ ] Ask for confirmation: *"Is this the correct workflow pattern for this project?"*
   - **Expected result**: Confirmed understanding of complete planning-to-implementation workflow

**Success Criteria**: Demonstration of complete workflow understanding from task planning through implementation with practical experience using both planning and implementation tools.

### Complete Workflow Demonstration: From Planning to Implementation

**Real Example**: Here's how the complete workflow works in practice:

#### Step 1: Planning Phase Example

- **Scenario**: You need to improve the Digital Inspection documentation
- **Use task planner**: *"Using task-planner chat mode, create a plan to add missing prerequisites section to Digital Inspection documentation"*
- **Create research notes**: Save findings in `.copilot-tracking/research/` if working on real projects
- **Expected output**: Comprehensive plan with research, implementation, and validation phases

#### Step 2: Implementation Phase Transition

- **Switch modes**: Open `.github/instructions/task-implementation.instructions.md`
- **Follow systematic process**:
  1. Read the complete plan file to understand scope
  2. Gather ALL required context (read referenced files)
  3. Implement tasks systematically in order
  4. Mark tasks complete [x] and track progress
- **Expected behavior**: Systematic execution following plan exactly

#### Step 3: Implementation Example

- **Task**: "Add prerequisites section to documentation"
- **Systematic approach**:
  1. Read current documentation file
  2. Analyze existing patterns for prerequisites
  3. Create working content that meets requirements
  4. Validate implementation and fix issues
  5. Mark task complete [x]
- **Expected result**: Working implementation that meets all task requirements

#### Step 4: Validation and Iteration

- **Use prompts for guidance**: *"Review my implementation and suggest improvements"*
- **Quality check**: Ensure implementation meets success criteria
- **Continue or iterate**: Based on validation results
- **Expected outcome**: High-quality implementation ready for use

**Workflow Transition Indicators**:

- ✅ **Ready for implementation**: Plan has specific file paths, clear actions, defined success criteria
- ⚠️ **Need more planning**: Vague tasks, unclear requirements, missing context
- 🔄 **Ready for validation**: Implementation complete, need quality review and feedback

### Chat Mode Discovery and Exploration Exercise

**Practice Exercise**: Discover and explore the available AI assistance modes:

**1. Explore the Chat Modes Infrastructure**:

- Navigate to `.github/chatmodes/` folder in your file explorer
- List all available chat mode files:
  - `task-planner.chatmode.md` - for systematic planning
  - `prompt-builder.chatmode.md` - for prompt engineering
  - `praxisworx-kata-coach.chatmode.md` - for learning assistance
  - `praxisworx-lab-coach.chatmode.md` - for lab guidance
- **Expected result**: Understanding of available specialized AI assistance modes

**2. Deep Dive into Task Planner Chat Mode**:

- Open `.github/chatmodes/task-planner.chatmode.md`
- Read lines 1-50 to understand the specialized planning approach
- Find the planning template (around line 100) and examine its structure
- Ask GitHub Copilot: *"Explain the task planner chat mode methodology and when I should use it"*
- **Expected result**: Clear understanding of task planning methodology and template structure

**3. Practice Chat Mode Usage**:

- Try this command: *"Using the task-planner chat mode approach, help me create a research plan for understanding edge AI documentation patterns"*
- Compare with general chat: *"Help me create a research plan for understanding edge AI documentation patterns"*
- Notice the difference in specificity and methodology
- **Expected result**: Experience with specialized vs general AI assistance approaches

**4. Validation of Chat Mode Understanding**:

- Ask: *"When should I use task-planner chat mode vs prompt files vs instruction files for AI assistance?"*
- Verify your understanding: *"I should use task-planner when I need to create systematic plans, prompts when I need guidance, and instructions when I need to implement plans. Is this correct?"*
- **Expected result**: Confirmed understanding of when to use each assistance approach

### File-Specific Exploration and Validation Checkpoints

**Validation Exercise**: Confirm your understanding through specific file exploration:

**1. Task Planning Template Structure Validation**:

- Open `.github/chatmodes/task-planner.chatmode.md` and go to line 100-150
- Find the plan template section and examine the required elements:
  - Overview and Objectives sections
  - Research Summary with file references
  - Implementation Plan with phases and tasks
  - Dependencies and Success Criteria
- Ask: *"What are the required elements of a task plan according to the template?"*
- **Expected result**: Understanding of professional task plan structure requirements

**2. Implementation Instructions Deep Dive**:

- Open `.github/instructions/task-implementation.instructions.md` and read lines 1-100
- Find the "Core Implementation Process" section
- Identify the systematic implementation workflow steps
- Ask: *"What is the systematic process for implementing task plans according to the instructions?"*
- **Expected result**: Understanding of how plans transition to implementation with specific steps

**3. Real Scenario Documentation Analysis**:

- Open `docs/project-planning/scenarios/digital-inspection-survey/README.md`
- Read the first 50 lines to understand the scenario structure
- Identify what information is provided vs what might be missing
- Ask: *"Based on this scenario structure, what documentation improvements would have the highest impact?"*
- **Expected result**: Practical understanding of documentation analysis with specific improvement opportunities

**4. Progress Validation Checkpoints**:

- [ ] Can navigate to any mentioned file path without assistance
- [ ] Can explain the difference between prompts, instructions, and chat modes with examples
- [ ] Can identify specific elements in the task planning template
- [ ] Can describe the implementation workflow transition process
- [ ] Can analyze documentation and identify improvement opportunities
- [ ] Can use appropriate AI assistance approach for different needs

## Validation

- [ ] Successfully navigated to specific project files using exact paths provided
- [ ] Demonstrated understanding of prompts vs instructions vs chat modes through hands-on practice
- [ ] Completed file exploration and documented specific gaps in Digital Inspection documentation
- [ ] Used task planning chat mode to create categorized improvement strategy
- [ ] Created professional task plan following project template structure
- [ ] Demonstrated workflow transition from planning to implementation with practical steps
- [ ] Applied AI-assisted planning methodology with specific GitHub Copilot commands
- [ ] Validated understanding of complete planning-to-implementation workflow

## Next Steps

**Continue Learning**: Try "Repository Analysis Script Planning" kata for technical automation planning

**Apply Skills**: Use this methodology for actual documentation improvement projects in your work

## Resources

- [Task Planning Chat Mode][task-planning-mode] - Complete methodology documentation
- [Digital Inspection & Survey Scenario][digital-inspection-scenario] - Real documentation context
- [Technical Writing Best Practices][ms-style-guide] - Professional documentation standards

---

<!-- Reference Links -->
[task-planning-mode]: /.github/chatmodes/task-planner.chatmode.md
[digital-inspection-scenario]: /docs/project-planning/scenarios/digital-inspection-survey/README.md
[ms-style-guide]: https://learn.microsoft.com/en-us/style-guide/

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
