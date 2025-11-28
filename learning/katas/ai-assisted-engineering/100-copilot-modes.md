---
title: 'Kata: 100 - GitHub Copilot Modes'
description: Learn GitHub Copilot mode mechanics including Ask, Edit, and Agent modes with practical workflows for effective mode selection and transitions
author: Edge AI Team
ms.date: 2025-01-24
kata_id: ai-assisted-engineering-100-copilot-modes
kata_category:
  - ai-assisted-engineering
kata_difficulty: 1
estimated_time_minutes: 30
learning_objectives:
  - Learn GitHub Copilot Ask, Edit, and Agent mode mechanics
  - Understand mode-specific strengths and appropriate use cases
  - Practice effective mode selection based on task characteristics
  - Develop fluency in mode transitions during development workflows
prerequisite_katas:
  - ai-assisted-engineering-100-ai-development-fundamentals
technologies:
  - GitHub Copilot
  - GitHub Copilot Chat
  - GitHub Copilot Edit Chat Mode
  - GitHub Copilot Agent Mode
  - VS Code
success_criteria:
  - Activate and use each Copilot mode effectively
  - Successfully transition between modes for appropriate tasks
  - Demonstrate understanding of mode-specific strengths and use cases
  - Complete practical workflows using each mode effectively
ai_coaching_level: guided
scaffolding_level: heavy
hint_strategy: progressive
common_pitfalls:
  - "Using Edit chat mode for exploratory questions - use Ask mode instead"
  - "Using Ask mode for multi-file changes - switch to Edit chat mode"
  - "Forgetting to provide context (@workspace or #-mentions) in Edit chat mode"
  - "Not leveraging Agent mode for complex multi-step research tasks"
requires_azure_subscription: false
requires_local_environment: true
tags:
  - ai-assisted-engineering
search_keywords:
  - copilot ask mode
  - copilot edit chat mode
  - copilot agent mode
  - mode transitions
  - github copilot modes
  - chat mode selector
---

## Quick Context

**You'll Learn**: GitHub Copilot mode mechanics including Ask, Edit, and Agent modes with practical workflows for effective mode selection and transitions.

**Prerequisites**: Completion of AI Development Fundamentals kata (ai-assisted-engineering-100-ai-development-fundamentals), VS Code with GitHub Copilot extension

**Real Challenge**: You're working on a feature that requires understanding existing code (Ask), making coordinated changes across files (Edit), and researching implementation patterns (Agent). Knowing which mode to use and how to transition between them is crucial for productivity.

**Your Task**: Practice activating and using each Copilot mode, understand their strengths, and develop intuition for mode selection based on task characteristics.

## Essential Setup

Complete these prerequisite checks to ensure a successful learning experience:

**Required** (check these first):

- [ ] Completed kata 100-ai-development-fundamentals
- [ ] VS Code with GitHub Copilot extension active and enabled
- [ ] GitHub Copilot subscription with chat functionality available
- [ ] Access to project workspace with folder navigation capability

**Quick Validation**: Verify you can open GitHub Copilot Chat and see the mode selector dropdown (Ask/Edit/Agent).

**Understanding Check**: This kata teaches you to effectively use and transition between GitHub Copilot's Ask, Edit, and Agent modes for maximum development productivity.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** chat mode for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** mode and say:
>
> ```text
> I'm working on GitHub Copilot Modes kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Ask Mode - Questions and Exploration (10 minutes)

**What You'll Do**: Learn Ask mode for conversational Q&A and code exploration

<!-- AI_COACH: Ask mode is your conversational partner for understanding code and exploring options. If learners struggle with prompt formulation, guide them to be specific: reference file paths, function names, or concepts directly. Ask mode excels at "What is...", "How does...", "Why should..." questions. -->

**Steps**:

1. **Understand** Ask mode fundamentals
   - [ ] Open GitHub Copilot Chat (default Ask mode)
   - [ ] Verify the mode selector shows "Ask" (or is in default chat state)
   - [ ] **Key concept**: Ask mode provides conversational Q&A with workspace context
   - [ ] **Best for**: Understanding code, getting explanations, exploring options
   - [ ] **Expected result**: Chat panel open and ready for questions

2. **Practice** architectural questions
   - [ ] Ask: "What is the purpose of the src/000-cloud/ directory structure?"
   - [ ] Review the explanation of component organization
   - [ ] Ask: "How does src/000-cloud/010-security-identity work with other components?"
   - [ ] Note the dependencies and integration patterns described
   - [ ] **Expected result**: Clear explanations of project architecture and component relationships

3. **Practice** code-specific queries
   - [ ] Ask: "Show me an example of how to use the security-identity component"
   - [ ] Request: "@workspace Find terraform files in src/000-cloud/ and explain their purpose"
   - [ ] **Pro tip**: Use @workspace for project-aware context in responses
   - [ ] **Expected result**: Code examples and file references provided with context

4. **Validate** Ask mode understanding
   - [ ] Try asking: "What are the best practices for deploying edge AI solutions?"
   - [ ] Compare with: "@workspace What deployment patterns does this project use for edge AI?"
   - [ ] Notice how @workspace improves specificity and relevance
   - [ ] **Success check**: Comfortable formulating effective questions for Ask mode

### Task 2: Edit Chat Mode - Coordinated Multi-file Exploration (12 minutes)

**What You'll Do**: Learn Edit chat mode for exploring coordination patterns across multiple files in real repository code using @workspace and #-mentions

<!-- AI_COACH: Edit chat mode is task-oriented for both exploration and execution. This task focuses on read-only exploration to understand patterns. Guide learners: @workspace for discovery, #-mentions for known files. Emphasize reviewing proposed changes without applying them to production code. -->

**Steps**:

1. **Understand** Edit chat mode fundamentals
   - [ ] **Key concept**: Edit chat mode coordinates exploration and changes across multiple files using context mechanisms
   - [ ] **Activation**: Select "Edit" from the mode selector dropdown in Chat panel (Ctrl+Alt+I / Cmd+Alt+I)
   - [ ] **Best for**: Multi-file exploration, consistent updates, refactoring, coordination patterns
   - [ ] **Context**: Use @workspace for discovery or #-mentions for specific files
   - [ ] **Dual purpose**: Exploration (propose changes to understand) and Execution (apply changes)
   - [ ] **Expected result**: Clear understanding of Edit chat mode's purpose and activation via mode selector

2. **Compare** Edit chat mode vs. Ask mode
   - [ ] **Ask mode**: Questions, conceptual exploration, explanations, conversational
   - [ ] **Edit chat mode**: Multi-file exploration with diffs, coordinated changes, @workspace/#-mentions context, task-oriented
   - [ ] **Transition signal**: When you say "I need to see how this works across files" or "I need to update this in multiple files"
   - [ ] **Expected result**: Understanding when to switch from Ask to Edit chat mode

3. **Discover** real repository files for exploration
   - [ ] Navigate to `src/000-cloud/` in File Explorer
   - [ ] Notice components: 010-security-identity, 020-observability, 030-data, 040-messaging
   - [ ] Each component has `terraform/` directories with multiple .tf files
   - [ ] Open `src/000-cloud/010-security-identity/terraform/variables.tf` to see structure
   - [ ] **Expected result**: Familiarity with real infrastructure components for Edit chat mode practice

4. **Activate** Edit chat mode via mode selector
   - [ ] Open GitHub Copilot Chat: `Ctrl+Alt+I` / `Cmd+Alt+I`
   - [ ] Click the mode selector dropdown at the top of the chat panel
   - [ ] Select "Edit" mode from the dropdown
   - [ ] Verify the mode indicator shows "Edit"
   - [ ] **Expected result**: Chat panel in Edit chat mode, ready for multi-file editing

5. **Explore** coordination patterns with @workspace context (READ-ONLY)
   - [ ] In Chat panel (Edit mode), enter:

   ```text
   @workspace In src/000-cloud/ show me all variables.tf files and identify common variable patterns that appear across multiple components
   ```

   - [ ] Wait for Edit chat mode to discover the files and show patterns
   - [ ] Review the common patterns identified (location, environment, resource_prefix)
   - [ ] **Pro tip**: Edit chat mode can discover and analyze patterns across many files
   - [ ] **DO NOT APPLY** any changes - this is exploration only
   - [ ] **Expected result**: Understanding how Edit chat mode discovers and analyzes patterns across multiple files

6. **Practice** using #-file mentions for specific targeting
   - [ ] In Chat panel (still in Edit mode), continue with new prompt:

   ```text
   #file:src/000-cloud/010-security-identity/terraform/main.tf #file:src/000-cloud/020-observability/terraform/main.tf Show me the resource definitions in these two files and identify common patterns
   ```

   - [ ] Review the specific file content and patterns identified
   - [ ] Notice how #-mentions explicitly target known files vs @workspace discovery
   - [ ] **Pro tip**: Use #-mentions when you know exactly which files to explore; use @workspace for discovery
   - [ ] **Expected result**: Comfortable using both @workspace and #-mentions for Edit chat mode context

### Task 3: Agent Mode - Autonomous Research (8 minutes)

**What You'll Do**: Learn Agent mode for autonomous multi-step research and information gathering

<!-- AI_COACH: Agent mode is autonomous and research-oriented. If learners struggle with agent tasks, guide them to formulate clear, self-contained requests: "Research X and provide Y." Agent mode excels at: searching codebases, gathering information from multiple sources, and synthesizing findings. -->

**Steps**:

1. **Understand** Agent Mode fundamentals
   - [ ] **Key concept**: Agent mode performs autonomous multi-step research
   - [ ] **Activation**: Select "Agent" mode in Copilot Chat mode selector dropdown
   - [ ] **Best for**: Codebase research, pattern discovery, multi-file analysis
   - [ ] **Operation**: Agent explores autonomously and reports comprehensive findings
   - [ ] **Expected result**: Clear understanding of Agent mode's autonomous nature

2. **Understand** mode selection decision matrix
   - [ ] **Task**: "How does X work?" → **Mode**: Ask → **Why**: Conversational explanation
   - [ ] **Task**: "Update Y in files A, B, C" → **Mode**: Edit chat mode → **Why**: Coordinated changes
   - [ ] **Task**: "Find all uses of pattern Z" → **Mode**: Agent → **Why**: Autonomous search
   - [ ] **Task**: "Explain this function" → **Mode**: Ask → **Why**: Single-file context
   - [ ] **Task**: "Refactor across modules" → **Mode**: Edit chat mode → **Why**: Multi-file coordination
   - [ ] **Task**: "Research implementation options" → **Mode**: Agent → **Why**: Multi-source gathering
   - [ ] **Expected result**: Internalized decision framework for mode selection

3. **Activate** Agent mode
   - [ ] Open GitHub Copilot Chat
   - [ ] Click the mode selector dropdown at the top of the chat panel
   - [ ] Select "Agent" mode from the options
   - [ ] Verify the indicator shows "Agent" mode is active
   - [ ] **Expected result**: Agent mode activated and ready for research tasks

4. **Practice** codebase research
   - [ ] Request: "Search the codebase for all terraform components and summarize their purposes"
   - [ ] Wait for agent to complete autonomous search (this takes longer than Ask mode)
   - [ ] **Pro tip**: Agent mode takes more time but provides comprehensive, multi-source results
   - [ ] Review the summary of terraform components provided
   - [ ] **Expected result**: Comprehensive overview of terraform components with purposes and locations

5. **Compare** Agent vs. Ask mode
   - [ ] Switch back to Ask mode using the mode selector
   - [ ] Ask the same question: "What terraform components are in this codebase?"
   - [ ] Notice the difference in approach: Ask gives immediate conversational response
   - [ ] Agent provided deeper, research-based analysis with multiple sources
   - [ ] **Expected result**: Understanding of when to use Agent (deep research) vs Ask (quick questions)

6. **Practice** mode transition workflow
   - [ ] **Scenario**: Research → Understand → Implement pattern
   - [ ] **Agent mode**: "Find all examples of component module patterns in src/"
   - [ ] **Switch to Ask mode**: "Explain the most common pattern you found"
   - [ ] **Switch to Edit chat mode**: Use @workspace or #-mentions to request pattern application
   - [ ] **Success check**: Comfortable transitioning between modes based on workflow stage

## Completion Check

**You've Succeeded When**:

- [ ] Successfully activated and used Ask mode for code exploration and questions
- [ ] Demonstrated effective use of Edit chat mode for multi-file exploration using @workspace and #-mentions on real repository files
- [ ] Practiced Agent mode for autonomous codebase research
- [ ] Completed practical workflow using all three modes with appropriate transitions
- [ ] Understand when to use each mode based on task characteristics (Ask for concepts, Edit for multi-file patterns, Agent for research)
- [ ] Comfortable with mode selector for activation and context provision strategies (@workspace vs #-mentions)
- [ ] Applied mode selection decision matrix to real development scenarios with production code

**Next Steps**: [200 - Copilot Edit Mode Basics][kata-200-basics] — Advanced multi-file workflows

---

## Reference Appendix

### Help Resources

- [Learning Kata Coach][kata-coach] — Your AI assistant for guided kata completion and troubleshooting
- [GitHub Copilot Documentation][ms-github-copilot] — Complete mode capabilities and feature reference
- [AI Development Fundamentals Kata][kata-100] — Foundation concepts for AI-assisted development

### Professional Tips

- **Ask mode**: Use for questions, explanations, and conceptual exploration. Add @workspace for project context.
- **Edit chat mode**: Dual purpose - exploration (propose changes to understand patterns) and execution (apply changes). Provide context via @workspace (discovery) or #-mentions (specific files).
- **Agent mode**: Best for research tasks requiring multiple sources or comprehensive analysis.
- **Mode transitions**: Research (Agent) → Understand (Ask) → Explore patterns (Edit chat mode) → Implement (Edit chat mode) is a common workflow.
- **Context strategies**: Use @workspace for discovery when file set unknown; use #-mentions for known file sets.
- **Exploration workflow**: Use Edit chat mode to propose changes on real code without applying them to learn coordination patterns safely.

### Troubleshooting

**Q: Edit chat mode doesn't show suggested changes**
**A**: Ensure you provided context via @workspace or #-mentions. Edit chat mode needs file context to discover and suggest changes.

**Q: Agent mode takes a very long time**
**A**: Normal behavior. Agent performs comprehensive research. Use Ask mode for quicker responses.

**Q: How do I know which mode I'm in?**
**A**: Check the mode indicator in Copilot Chat panel header or mode selector dropdown.

**Q: Can I switch modes mid-conversation?**
**A**: Yes! Use the mode selector dropdown to switch at any time. Context carries over where appropriate.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->

[kata-coach]: /.github/chatmodes/learning-kata-coach.chatmode.md
[ms-github-copilot]: https://docs.github.com/en/copilot
[kata-100]: /learning/katas/ai-assisted-engineering/100-ai-development-fundamentals.md
[kata-200-basics]: /learning/katas/ai-assisted-engineering/200-copilot-edit-mode-basics.md
