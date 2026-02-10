---
title: 'Kata: 100 - AI Development Fundamentals'
description: Learn AI-assisted, hyper-velocity engineering through hands-on practice with prompts, instructions, and custom agents
author: Edge AI Team
ms.date: 2025-01-20
kata_id: ai-assisted-engineering-100-ai-development-fundamentals
kata_category:
  - ai-assisted-engineering
kata_difficulty: 1
estimated_time_minutes: 30
learning_objectives:
  - Learn the fundamentals of AI-assisted, hyper-velocity engineering
  - Apply prompts, instructions, and custom agents for accelerated development
  - Implement AI-assisted workflow optimization strategies
  - Develop proficiency with AI development productivity measurement
prerequisite_katas: []
technologies:
  - GitHub Copilot
  - GitHub Copilot Chat
  - VS Code
  - AI-assisted development
success_criteria:
  - Learn AI-assisted engineering fundamentals and core tools
  - Understand prompts vs instructions vs custom agents
  - Apply hyper-velocity development methodologies
  - Implement AI-accelerated development workflows
ai_coaching_level: guided
scaffolding_level: heavy
hint_strategy: progressive
common_pitfalls: []
requires_azure_subscription: false
requires_local_environment: true
tags:
  - ai-assisted-engineering
search_keywords:
  - ai-assisted-development
  - github-copilot
  - hyper-velocity-engineering
  - ai-workflow-optimization
  - prompt-vs-instructions
---

## Quick Context

**You'll Learn**: Fundamentals of AI-assisted, hyper-velocity engineering through hands-on practice with prompts, instructions, and custom agents that accelerate development.

**Prerequisites**: VS Code with GitHub Copilot extension, basic understanding of file navigation and AI interaction concepts

**Real Challenge**: You're joining a development team that uses AI-assisted engineering extensively. You need to understand the difference between prompts, instructions, and custom agents, and when to use each approach for maximum productivity.

**Your Task**: Learn AI-assisted development fundamentals through hands-on practice with prompts, instructions, and custom agents that demonstrate practical application of these concepts.

## Essential Setup

Complete these prerequisite checks to ensure a successful learning experience:

**Required** (check these first):

- [ ] VS Code with GitHub Copilot extension active and enabled
- [ ] GitHub Copilot subscription with chat functionality available
- [ ] Access to project workspace with folder navigation capability
- [ ] Basic understanding of file navigation and AI interaction concepts

**Quick Validation**: Verify you can open GitHub Copilot Chat and navigate to `.github/prompts/`, `.github/instructions/`, and `.github/agents/` folders.

**Understanding Check**: This kata teaches you to distinguish between and effectively use different AI assistance approaches for maximum development productivity.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on 01 - AI Development Fundamentals kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Prompts vs Instructions Fundamentals (10 minutes)

**What You'll Do**: Understand and practice the core distinction between prompts and instructions

**Steps**:

1. **Explore** the difference between prompts and instructions
   - [ ] Navigate to `.github/prompts/` folder and open `getting-started.prompt.md`
   - [ ] Examine the coaching structure and guidance approach in the file
   - [ ] Navigate to `.github/instructions/` folder and open `task-implementation.instructions.md`
   - [ ] Compare the systematic, automation-focused approach in this file
   - [ ] Ask GitHub Copilot Chat: *"What's the difference between a prompt file and an instructions file in AI-assisted development?"*
   - [ ] **Expected result**: Clear understanding of when to use prompts (guidance/coaching) vs instructions (automation/systematic execution)

2. **Practice** with a sample prompt
   - [ ] Use GitHub Copilot Chat referencing the specific prompt: *"@workspace Using the getting started prompt from .github/prompts/getting-started.prompt.md, help me understand the project structure"*
   - [ ] Notice how prompts provide coaching and context-aware guidance
   - [ ] Try: *"Following the getting started guidance, what should I explore first in this project?"*
   - [ ] **Expected result**: Experience with prompt-based AI interaction that provides educational guidance

3. **Practice** with instructions
   - [ ] Reference the systematic approach: *"Following the task implementation instructions from .github/instructions/task-implementation.instructions.md, what steps should I take for systematic development?"*
   - [ ] Ask: *"Explain the systematic implementation process described in the task implementation instructions"*
   - [ ] Compare the procedural approach to the coaching approach from prompts
   - [ ] **Success check**: Understanding of both approaches and their appropriate use cases with specific examples

### Task 2: GitHub Copilot Custom Agents and Transitions (10 minutes)

**What You'll Do**: Discover available custom agents and Learn effective transitions between different AI assistance approaches

**Steps**:

1. **Discover** available custom agents infrastructure
   - [ ] Navigate to `.github/agents/` folder and explore available files
   - [ ] Open `learning-kata-coach.agent.md` - your specialized learning assistant
   - [ ] Explore additional agents for task planning and prompt engineering available via the [hve-core](https://github.com/microsoft/hve-core) VS Code extension
   - [ ] **Expected result**: Understanding of available specialized AI assistance modes

2. **Practice** workspace context mode
   - [ ] Use `@workspace` to get project-aware assistance
   - [ ] Try: *"@workspace explain the learning kata structure and learning approach"*
   - [ ] Ask: *"@workspace what AI assistance infrastructure is available in this project?"*
   - [ ] Notice how workspace context improves AI responses with project-specific knowledge
   - [ ] **Expected result**: Effective use of workspace-aware AI assistance

3. **Practice** custom agent transitions and specialization
   - [ ] Try the kata coach approach: *"Using the learning-kata-coach methodology, help me understand how to get maximum value from this learning experience"*
   - [ ] Compare with general chat: *"Help me understand how to get maximum value from this learning experience"*
   - [ ] Notice the difference in specialization and methodology
   - [ ] **Expected result**: Experience with specialized vs general AI assistance approaches

### Task 3: Practical AI-Assisted Development (15 minutes)

**What You'll Do**: Apply AI assistance fundamentals to real project exploration and development scenarios

**Steps**:

1. **Use** AI for structured project exploration
   - [ ] Ask GitHub Copilot Chat: *"@workspace help me understand how the Edge AI components are organized in the src/ folder"*
   - [ ] Follow up with: *"@workspace explain the difference between the 000-cloud and 100-edge component groupings"*
   - [ ] Explore specific components: *"@workspace describe the purpose of src/000-cloud/010-security-identity/"*
   - [ ] **Expected result**: Systematic understanding of project architecture through AI-assisted exploration

2. **Practice** AI-assisted problem-solving with real scenarios
   - [ ] Pick a specific blueprint to understand: *"@workspace explain the full-single-node-cluster blueprint and what it deploys"*
   - [ ] Use AI to break down complexity: *"What are the main components and dependencies in this blueprint?"*
   - [ ] Ask for implementation guidance: *"If I wanted to deploy this blueprint, what would be my first steps?"*
   - [ ] **Expected result**: Experience using AI for systematic problem-solving with concrete project elements

3. **Apply** workflow transitions in practice
   - [ ] Start with guidance: Use prompts for learning (*"@workspace help me understand deployment concepts"*)
   - [ ] Move to planning: Use custom agents for strategy (*"Using task planning methodology, how would I approach learning edge deployment?"*)
   - [ ] Consider implementation: Reference instructions (*"What systematic approach would I use to actually deploy components?"*)
   - [ ] **Expected result**: Demonstrated ability to choose and transition between AI assistance approaches based on current needs

4. **Apply** hyper-velocity principles with validation
   - [ ] Use AI to accelerate understanding rather than replace thinking
   - [ ] Ask follow-up questions to deepen comprehension: *"What should I explore next to build on this understanding?"*
   - [ ] Practice getting specific, actionable guidance: *"Give me three concrete next steps to apply what I've learned"*
   - [ ] **Validation checkpoint**: Can you explain the difference between @workspace queries and specialized custom agents?
   - [ ] **Success check**: Confident use of AI assistance for learning acceleration with understanding of when to use each approach

**Complete Workflow Integration Practice**:

**Real-World Application**: Experience the complete AI-assisted development workflow:

**Scenario-Based Practice**:

- **Learning Scenario**: "I want to understand how to deploy edge AI solutions"
  - **Guidance Phase**: *"@workspace help me understand deployment concepts for edge AI"* (using prompts)
  - **Planning Phase**: *"Using task planner methodology, create a learning plan for edge deployment"* (using custom agents)
  - **Implementation Phase**: *"Following systematic instructions, what steps would I take to deploy a blueprint?"* (using instructions)
  - **Validation Phase**: *"Review my understanding and suggest improvements"* (back to prompts)

**Workflow Transition Indicators**:

- ✅ **Use Prompts When**: Learning concepts, getting guidance, needing context, seeking validation
- ✅ **Use Custom Agents When**: Planning, specialized workflows, focused assistance, strategic thinking
- ✅ **Use Instructions When**: Implementing, following procedures, systematic execution, step-by-step work
- ✅ **Switch Approaches When**: Your needs change from learning → planning → implementing → validating

**Practice Exercise**:

1. Choose a topic you want to explore in this project
2. Start with prompts for initial understanding
3. Move to appropriate custom agent for deeper planning
4. Reference instructions for any systematic work
5. Return to prompts for validation and next steps

**Success Validation**: Can you fluidly move between AI assistance approaches based on what you're trying to accomplish?

## Completion Check

**You've Succeeded When**:

- [ ] Successfully navigated to specific files using exact paths (.github/prompts/, .github/instructions/, .github/agents/)
- [ ] Demonstrated clear understanding of prompts vs instructions vs custom agents through hands-on exploration
- [ ] Confidently used GitHub Copilot custom agents and workspace context for effective assistance
- [ ] Applied AI assistance to real project exploration with concrete results
- [ ] Demonstrated workflow transitions between guidance → planning → implementation → validation
- [ ] Experienced AI-assisted learning and problem-solving with practical project scenarios
- [ ] Applied hyper-velocity engineering principles while maintaining critical thinking and learning independence

---

## Reference Appendix

### Help Resources

- [Learning Kata Coach][kata-coach] — Your AI assistant for guided kata completion and troubleshooting
- [GitHub Copilot Documentation][ms-github-copilot] — Complete AI assistance capabilities and feature reference
- [Project Prompts][project-prompts] — Available coaching guidance files for learning and problem-solving
- [Project Instructions][project-instructions] — Automation and systematic implementation approaches
- [Project Custom Agents][project-agents] — Specialized AI assistance modes for focused workflows

### Professional Tips

- Start with prompts for guidance, use custom agents for planning, and reference instructions for systematic implementation.
- Use @workspace to provide project-aware context and improve AI response accuracy.
- Practice fluid transitions between AI assistance approaches based on your current needs.
- Leverage specialized custom agents for focused, workflow-specific assistance rather than general chat.
- Balance AI acceleration with critical thinking—use AI to speed understanding, not replace it.

### Troubleshooting

- If AI responses lack context, verify you're using @workspace for project-aware assistance.
- For specialized workflows, check if an appropriate custom agent exists in `.github/agents/` before using general chat.
- When choosing between prompts and instructions, ask: "Do I need guidance or systematic execution?"
- If confused about when to use each approach, review the AI-assisted development workflow: Guidance → Planning → Implementation → Validation.
- For best results, be specific in your queries and provide relevant context about what you're trying to accomplish.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction, then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
[kata-coach]: /.github/agents/learning-kata-coach.agent.md
[ms-github-copilot]: https://docs.github.com/en/copilot
[project-prompts]: /.github/prompts/
[project-instructions]: /.github/instructions/
[project-agents]: /.github/agents/
