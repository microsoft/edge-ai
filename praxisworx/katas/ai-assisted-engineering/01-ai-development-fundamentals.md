---
title: 01 - AI Development Fundamentals
description: Master the fundamentals of AI-assisted, hyper-velocity engineering through hands-on practice with prompts, instructions, and chat modes that accelerate development workflows
author: Edge AI Team
ms.date: 2025-06-15
ms.topic: kata
estimated_reading_time: 15
difficulty: beginner
duration: 25-35 minutes
keywords:
  - praxisworx
  - ai-assisted engineering
  - prompts vs instructions
  - hyper-velocity development
  - chat modes
  - numbered progression
---

## What You'll Learn

Master the fundamentals of AI-assisted, hyper-velocity engineering through hands-on practice with core tools and methodologies.

**Learning Objectives**:

- Understand the difference between prompts (.prompt.md) and instructions (.instructions.md) and when to use each
- Master GitHub Copilot Chat modes and transitions for effective AI assistance
- Learn principles of hyper-velocity engineering and AI-assisted development workflows
- Practice hands-on with prompts to build confidence and competence

**Prerequisites**: VS Code with GitHub Copilot extension, active Copilot subscription, basic development concepts

**Real-World Context**: AI-assisted development is transforming software engineering by enabling hyper-velocity workflows. Understanding prompts vs instructions and effective AI interaction patterns is essential for modern development productivity.

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
I'm working on AI Development Fundamentals kata and want interactive coaching with progress tracking and learning evaluation.
```

**💡 Pro Tip**: Your coach can see your checkbox progress when you're using the local docs (`npm run docs:training`) and help you manage it!

## Practice Scenario

You're joining a development team that uses AI-assisted engineering extensively. You need to understand:

- **Prompts vs Instructions**: When to use coaching (.prompt.md) vs automation (.instructions.md)
- **Chat Modes**: How to transition between different AI assistance modes effectively
- **Hyper-Velocity Engineering**: Smart AI assistance patterns for productive development
- **Practical Application**: Hands-on experience with AI tools in real development scenarios

**Your Challenge**: Master the fundamentals through hands-on practice with prompts, instructions, and chat modes that demonstrate AI-assisted development principles.

**Methodology**: Use progressive AI interaction: (1) Understand prompt vs instruction concepts, (2) Practice with different chat modes, (3) Apply hyper-velocity engineering principles

### Essential Setup

**Required** (check these first):

- [ ] VS Code with GitHub Copilot extension active and enabled
- [ ] GitHub Copilot subscription with chat functionality available
- [ ] Access to project workspace with folder navigation capability
- [ ] Basic understanding of file navigation and AI interaction concepts

**Quick Validation**:

- Can you navigate to `.github/prompts/` folder and see getting-started.prompt.md?
- Can you open GitHub Copilot Chat and see the chat interface?
- Can you navigate to `.github/instructions/` and find task-implementation.instructions.md?
- Can you open `.github/chatmodes/` and see the available chat mode files?

**Understanding Check**: This kata teaches you to distinguish between and effectively use different AI assistance approaches for maximum development productivity.

## Understanding AI-Assisted Development Infrastructure

Before diving into the tasks, you need to understand the three core AI assistance approaches available in this project:

### Prompts vs Instructions vs Chat Modes: The Complete Picture

**Overview Resources** (start here for context):

- **[Prompts Overview][project-prompts]**: Complete guide to 11 coaching and guidance prompts
- **[Instructions Overview][project-instructions]**: Reference for 7 systematic implementation instruction files
- **[Chat Modes Overview][project-chatmodes]**: Documentation for 4 specialized AI assistance modes

**Prompts** (`.prompt.md` files in `.github/prompts/`):

- **Purpose**: Coaching and guidance approach for learning and problem-solving
- **When to use**: When you need step-by-step guidance, context-aware assistance, or educational support
- **Example exploration**: Open `.github/prompts/getting-started.prompt.md` and notice the coaching structure
- **Try this**: *"@workspace Using the getting started prompt approach, help me understand how to deploy a blueprint"*

**Instructions** (`.instructions.md` files in `.github/instructions/`):

- **Purpose**: Systematic, procedural automation for consistent execution
- **When to use**: When you have a plan and need systematic implementation with specific steps
- **Example exploration**: Open `.github/instructions/task-implementation.instructions.md` and see the systematic process
- **Try this**: *"Following the task implementation instructions, explain the systematic process for executing plans"*

**Chat Modes** (`.chatmode.md` files in `.github/chatmodes/`):

- **Purpose**: Specialized AI assistance modes for specific workflows and domains
- **When to use**: When you need focused assistance for particular tasks like planning, prompt building, or learning
- **Example exploration**: Open `.github/chatmodes/praxisworx-kata-coach.chatmode.md` and examine the specialized coaching approach
- **Try this**: *"Using the kata coach methodology, help me understand how to get the most from this learning experience"*

### The AI-Assisted Development Workflow

**Understanding the Flow**: Guidance → Planning → Implementation → Validation

1. **Learning Phase**: Use prompts for guidance and understanding
2. **Planning Phase**: Use specialized chat modes for focused strategy creation
3. **Implementation Phase**: Use instructions for systematic execution
4. **Validation Phase**: Use prompts for review and improvement guidance

**Your Goal**: Master switching between these approaches fluidly based on your current needs and the type of work you're doing.

## Tasks

### Task 1: Prompts vs Instructions Fundamentals (10 minutes)

**What You'll Do**: Understand and practice the core distinction between prompts and instructions

**Steps**:

1. **Explore** the difference between prompts and instructions
   - [ ] Navigate to `.github/prompts/` folder and open `getting-started.prompt.md`
   - [ ] Examine the coaching structure and guidance approach in the file
   - [ ] Navigate to `.github/instructions/` folder and open `task-implementation.instructions.md`
   - [ ] Compare the systematic, automation-focused approach in this file
   - [ ] Ask GitHub Copilot Chat: *"What's the difference between a prompt file and an instructions file in AI-assisted development?"*
   - **Expected result**: Clear understanding of when to use prompts (guidance/coaching) vs instructions (automation/systematic execution)

2. **Practice** with a sample prompt
   - [ ] Use GitHub Copilot Chat referencing the specific prompt: *"@workspace Using the getting started prompt from .github/prompts/getting-started.prompt.md, help me understand the project structure"*
   - [ ] Notice how prompts provide coaching and context-aware guidance
   - [ ] Try: *"Following the getting started guidance, what should I explore first in this project?"*
   - **Expected result**: Experience with prompt-based AI interaction that provides educational guidance

3. **Practice** with instructions
   - [ ] Reference the systematic approach: *"Following the task implementation instructions from .github/instructions/task-implementation.instructions.md, what steps should I take for systematic development?"*
   - [ ] Ask: *"Explain the systematic implementation process described in the task implementation instructions"*
   - [ ] Compare the procedural approach to the coaching approach from prompts
   - **Success check**: Understanding of both approaches and their appropriate use cases with specific examples

### Task 2: GitHub Copilot Chat Modes and Transitions (10 minutes)

**What You'll Do**: Discover available chat modes and master effective transitions between different AI assistance approaches

**Steps**:

1. **Discover** available chat modes infrastructure
   - [ ] Navigate to `.github/chatmodes/` folder and explore available files
   - [ ] Open `praxisworx-kata-coach.chatmode.md` - your specialized learning assistant
   - [ ] Open `task-planner.chatmode.md` - for systematic planning assistance
   - [ ] Open `prompt-builder.chatmode.md` - for prompt engineering workflows
   - **Expected result**: Understanding of available specialized AI assistance modes

2. **Practice** workspace context mode
   - [ ] Use `@workspace` to get project-aware assistance
   - [ ] Try: *"@workspace explain the PraxisWorx kata structure and learning approach"*
   - [ ] Ask: *"@workspace what AI assistance infrastructure is available in this project?"*
   - [ ] Notice how workspace context improves AI responses with project-specific knowledge
   - **Expected result**: Effective use of workspace-aware AI assistance

3. **Practice** chat mode transitions and specialization
   - [ ] Try the kata coach approach: *"Using the praxisworx-kata-coach methodology, help me understand how to get maximum value from this learning experience"*
   - [ ] Compare with general chat: *"Help me understand how to get maximum value from this learning experience"*
   - [ ] Notice the difference in specialization and methodology
   - **Expected result**: Experience with specialized vs general AI assistance approaches

### Task 3: Practical AI-Assisted Development (15 minutes)

**What You'll Do**: Apply AI assistance fundamentals to real project exploration and development scenarios

**Steps**:

1. **Use** AI for structured project exploration
   - [ ] Ask GitHub Copilot Chat: *"@workspace help me understand how the Edge AI components are organized in the src/ folder"*
   - [ ] Follow up with: *"@workspace explain the difference between the 000-cloud and 100-edge component groupings"*
   - [ ] Explore specific components: *"@workspace describe the purpose of src/000-cloud/010-security-identity/"*
   - **Expected result**: Systematic understanding of project architecture through AI-assisted exploration

2. **Practice** AI-assisted problem-solving with real scenarios
   - [ ] Pick a specific blueprint to understand: *"@workspace explain the full-single-node-cluster blueprint and what it deploys"*
   - [ ] Use AI to break down complexity: *"What are the main components and dependencies in this blueprint?"*
   - [ ] Ask for implementation guidance: *"If I wanted to deploy this blueprint, what would be my first steps?"*
   - **Expected result**: Experience using AI for systematic problem-solving with concrete project elements

3. **Apply** workflow transitions in practice
   - [ ] Start with guidance: Use prompts for learning (*"@workspace help me understand deployment concepts"*)
   - [ ] Move to planning: Use chat modes for strategy (*"Using task planning methodology, how would I approach learning edge deployment?"*)
   - [ ] Consider implementation: Reference instructions (*"What systematic approach would I use to actually deploy components?"*)
   - **Expected result**: Demonstrated ability to choose and transition between AI assistance approaches based on current needs

4. **Apply** hyper-velocity principles with validation
   - [ ] Use AI to accelerate understanding rather than replace thinking
   - [ ] Ask follow-up questions to deepen comprehension: *"What should I explore next to build on this understanding?"*
   - [ ] Practice getting specific, actionable guidance: *"Give me three concrete next steps to apply what I've learned"*
   - **Validation checkpoint**: Can you explain the difference between @workspace queries and specialized chat modes?
   - **Success check**: Confident use of AI assistance for learning acceleration with understanding of when to use each approach

### Complete Workflow Integration Practice

**Real-World Application**: Experience the complete AI-assisted development workflow:

**Scenario-Based Practice**:

- **Learning Scenario**: "I want to understand how to deploy edge AI solutions"
  - **Guidance Phase**: *"@workspace help me understand deployment concepts for edge AI"* (using prompts)
  - **Planning Phase**: *"Using task planner methodology, create a learning plan for edge deployment"* (using chat modes)
  - **Implementation Phase**: *"Following systematic instructions, what steps would I take to deploy a blueprint?"* (using instructions)
  - **Validation Phase**: *"Review my understanding and suggest improvements"* (back to prompts)

**Workflow Transition Indicators**:

- ✅ **Use Prompts When**: Learning concepts, getting guidance, needing context, seeking validation
- ✅ **Use Chat Modes When**: Planning, specialized workflows, focused assistance, strategic thinking
- ✅ **Use Instructions When**: Implementing, following procedures, systematic execution, step-by-step work
- ✅ **Switch Approaches When**: Your needs change from learning → planning → implementing → validating

**Practice Exercise**:

1. Choose a topic you want to explore in this project
2. Start with prompts for initial understanding
3. Move to appropriate chat mode for deeper planning
4. Reference instructions for any systematic work
5. Return to prompts for validation and next steps

**Success Validation**: Can you fluidly move between AI assistance approaches based on what you're trying to accomplish?

## Validation

- [ ] Successfully navigated to specific files using exact paths (.github/prompts/, .github/instructions/, .github/chatmodes/)
- [ ] Demonstrated clear understanding of prompts vs instructions vs chat modes through hands-on exploration
- [ ] Confidently used GitHub Copilot Chat modes and workspace context for effective assistance
- [ ] Applied AI assistance to real project exploration with concrete results
- [ ] Demonstrated workflow transitions between guidance → planning → implementation → validation
- [ ] Experienced AI-assisted learning and problem-solving with practical project scenarios
- [ ] Validated understanding through hands-on verification exercises and self-assessment
- [ ] Applied hyper-velocity engineering principles while maintaining critical thinking and learning independence

### AI Assistance Proficiency Validation

**Validation Exercise**: Confirm your understanding through hands-on verification:

**1. Infrastructure Discovery Validation**:

- [ ] Can navigate to `.github/prompts/` and identify at least 3 different prompt files
- [ ] Can navigate to `.github/instructions/` and explain the difference from prompts
- [ ] Can navigate to `.github/chatmodes/` and identify available specialized assistance modes
- **Validation question**: *"What are the three main types of AI assistance available in this project and when should I use each?"*

**2. Practical Application Validation**:

- [ ] Can demonstrate using @workspace for project-aware assistance
- [ ] Can show the difference between general chat and specialized chat modes
- [ ] Can explain when to use prompts vs instructions vs chat modes with specific examples
- **Validation exercise**: Ask GitHub Copilot to help you choose the right approach for a specific task

**3. Workflow Understanding Validation**:

- [ ] Can describe the AI-assisted development workflow (Guidance → Planning → Implementation → Validation)
- [ ] Can demonstrate transitioning between different AI assistance approaches appropriately
- [ ] Can apply hyper-velocity principles while maintaining critical thinking
- **Success indicator**: Confidence in choosing and using appropriate AI assistance for different development needs

## Next Steps

**Continue Learning**: Try "Getting Started Basics" kata to apply these fundamentals to specific development workflows

**Apply Skills**: Use AI assistance patterns learned here in your daily development work

## Resources

- [PraxisWorx Kata Coach][kata-coach] - Your AI assistant for guided kata completion and troubleshooting
- [GitHub Copilot Documentation][ms-github-copilot] - Complete AI assistance capabilities
- [Project Prompts][project-prompts] - Available coaching guidance
- [Project Instructions][project-instructions] - Automation and systematic approaches

---

<!-- Reference Links -->
[kata-coach]: /.github/chatmodes/praxisworx-kata-coach.chatmode.md
[ms-github-copilot]: https://docs.github.com/en/copilot
[project-prompts]: /.github/prompts/
[project-instructions]: /.github/instructions/
[project-chatmodes]: /.github/chatmodes/

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
